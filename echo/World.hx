package echo;

import echo.Listener;
import echo.data.Data;
import echo.data.Options;
import echo.shape.Rect;
import echo.util.AABB;
import echo.util.Disposable;
import echo.util.History;
import echo.util.QuadTree;
import echo.math.Vector2;
/**
 * A `World` is an Object representing the state of a Physics simulation and it configurations. 
 */
@:using(echo.Echo)
class World implements Disposable {
  /**
   * Width of the World, extending right from the World's X position.
   */
  public var width(default, set):Float;
  /**
   * Height of the World, extending down from the World's Y position.
   */
  public var height(default, set):Float;
  /**
   * The World's position on the X axis.
   */
  public var x(default, set):Float;
  /**
   * The World's position on the Y axis.
   */
  public var y(default, set):Float;
  /**
   * The amount of acceleration applied to each `Body` member every Step.
   */
  public var gravity(default, null):Vector2;
  /**
   * The World's QuadTree for dynamic Bodies. Generally doesn't need to be touched.
   */
  public var quadtree:QuadTree;
  /**
   * The World's QuadTree for static Bodies. Generally doesn't need to be touched.
   */
  public var static_quadtree:QuadTree;

  public var listeners:Listeners;
  public var members:Array<Body>;
  public var count(get, never):Int;
  /**
   * The amount of iterations that occur each time the World is stepped. The higher the number, the more stable the Physics Simulation will be, at the cost of performance.
   */
  public var iterations:Int;
  /**
   * Flag that determines how Collisions in the World are resolved. Defaults to `false`.
   *
   * When `true` (arcade physics), Collisions only affect the Bodies' positions and velocities - Bodies are never rotated by a Collision.
   * When `false` (full physics), Collisions are resolved at their contact points, so that Bodies are also spun by off-center impacts and friction is applied along surfaces.
   *
   * Individual Listeners can override this setting with their own `arcade` option.
   */
  public var arcade:Bool;
  /**
   * Flag that determines whether the World optimizes Bodies that have come to rest by putting them to sleep. Defaults to `false`.
   *
   * A sleeping Body is skipped by the World's Physics calculations, and is not collided against other Bodies that
   * cannot move (other sleeping Bodies and static Bodies) - which can save a lot of work in a World where most Bodies
   * spend their time settled. It stays that way until something moving runs into it, it is moved or pushed, or it is
   * woken manually with `Body.wake()`.
   *
   * Note that two Bodies that have both fallen asleep stop reporting Collisions to a `Listener` (the same way two
   * static Bodies do), so a Listener's `exit` callback fires as they settle. Set `Body.can_sleep` to `false` on any
   * Body that needs to keep reporting Collisions while at rest.
   *
   * Tune when Bodies fall asleep with `Body.sleep_velocity`, `Body.sleep_rotational_velocity` and `Body.time_to_sleep`.
   */
  public var sleeping_bodies:Bool;

  public var history:Null<History<Array<BodyState>>>;

  public var accumulatedTime:Float = 0;

  var init:Bool;
  /**
   * Set while the World is tearing itself down, so that removing every Body doesn't bother waking the others.
   */
  var clearing:Bool = false;
  /**
   * Scratch values reused by `wake_bodies()`.
   */
  var wake_query:Array<QuadTreeData> = [];

  var woken:Array<Body> = [];

  var wake_bounds:AABB = AABB.get();

  public function new(options:WorldOptions) {
    members = options.members == null ? [] : options.members;
    init = false;
    width = options.width < 1?throw("World must have a width of at least 1") : options.width;
    height = options.height < 1?throw("World must have a width of at least 1") : options.height;
    x = options.x == null ? 0 : options.x;
    y = options.y == null ? 0 : options.y;
    gravity = new Vector2(options.gravity_x == null ? 0 : options.gravity_x, options.gravity_y == null ? 0 : options.gravity_y);
    reset_quadtrees();

    listeners = new Listeners(options.listeners);
    iterations = options.iterations == null ? 5 : options.iterations;
    arcade = options.arcade == null ? false : options.arcade;
    sleeping_bodies = options.sleeping_bodies == null ? false : options.sleeping_bodies;
    if (options.history != null) history = new History(options.history);
  }
  /**
   * Sets the size of the World. Only Bodies within the world bound will be collided
   * @param x The x position of the world bounds
   * @param y The y position of the world bounds
   * @param width The width of the world bounds
   * @param height The height of the world bounds
   */
  public inline function set(x:Float, y:Float, width:Float, height:Float) {
    init = false;
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    init = true;
    reset_quadtrees();
  }
  /**
   * Sets the size of the World based on a given shape.
   * @param s The shape to use as the boundaries of the World
   */
  public inline function set_from_shape(s:Shape) {
    x = s.left;
    y = s.top;
    width = s.right - x;
    height = s.bottom - y;
  }
  /**
   * Sets the size of the World based just large enough to encompass all the members.
   */
  public function set_from_members() {
    var l = 0.0;
    var r = 0.0;
    var t = 0.0;
    var b = 0.0;

    for (m in members) {
      for (s in m.shapes) {
        if (s.left < l) l = s.left;
        if (s.right > r) r = s.right;
        if (s.top < t) t = s.top;
        if (s.bottom > b) b = s.bottom;
      }
    }

    set(l, t, r - l, b - t);
  }

  public inline function center(?rect:Rect):Rect {
    return rect != null ? rect.set(x + (width * 0.5), y + (height * 0.5), width, height) : Rect.get(x + (width * 0.5), y + (height * 0.5), width, height);
  }

  public function add(body:Body):Body {
    if (body.world == this) return body;
    if (body.world != null) body.remove();
    body.world = this;
    body.dirty = true;
    members.push(body);
    body.quadtree_data = {id: body.id, bounds: body.bounds(), flag: false, body: body};
    body.is_static() ? static_quadtree.insert(body.quadtree_data) : quadtree.insert(body.quadtree_data);
    return body;
  }

  public function remove(body:Body):Body {
    // Anything that was resting on this Body has to start falling again
    if (sleeping_bodies && !clearing && body.shapes.length > 0) wake_bodies(body.stored_bounds());
    quadtree.remove(body.quadtree_data);
    static_quadtree.remove(body.quadtree_data);
    members.remove(body);
    body.world = null;
    return body;
  }
  /**
   * Wakes every sleeping `Body` in the World, or just the ones overlapping the `bounds` passed in.
   *
   * Sleeping Bodies wake on their own when something moving runs into them, but the World cannot tell when the ground
   * beneath them changes - so call this after moving a static Body (or otherwise rearranging the World) to get any
   * Bodies that were resting on it moving again.
   * @param bounds Optional bounds to limit which Bodies are woken.
   */
  public function wake_bodies(?bounds:AABB) {
    if (bounds == null) {
      for_each_dynamic(b -> b.wake());
      return;
    }

    // Spread outwards from the bounds - whatever was resting on a Body that just woke up has to wake up too, or it
    // would be left hanging in mid air. Each Body only wakes once, so this settles quickly.
    woken.resize(0);
    wake_overlapping(bounds);
    var i = 0;
    while (i < woken.length) {
      var body = woken[i++];
      wake_overlapping(body.stored_bounds(wake_bounds));
    }
    woken.resize(0);
  }

  inline function wake_overlapping(bounds:AABB) {
    wake_query.resize(0);
    quadtree.query(bounds, wake_query);
    for (data in wake_query) if (data.body != null && data.body.sleeping) {
      data.body.wake();
      woken.push(data.body);
    }
  }

  public inline function iterator():Iterator<Body> return members.iterator();
  /**
   * Returns a new Array containing every dynamic `Body` in the World.
   */
  public inline function dynamics():Array<Body> return members.filter(b -> return b.is_dynamic());
  /**
   * Returns a new Array containing every static `Body` in the World.
   */
  public inline function statics():Array<Body> return members.filter(b -> return b.is_static());
  /**
   * Runs a function on every `Body` in the World
   * @param f Function to perform on each `Body`.
   * @param recursive Currently not supported.
   */
  public inline function for_each(f:Body->Void, recursive:Bool = true) for (b in members) f(cast b);
  /**
   * Runs a function on every dynamic `Body` in the World
   * @param f Function to perform on each dynamic `Body`.
   * @param recursive Currently not supported.
   */
  public inline function for_each_dynamic(f:Body->Void, recursive:Bool = true) for (b in members) if (b.is_dynamic()) f(cast b);
  /**
   * Runs a function on every static `Body` in the World
   * @param f Function to perform on each static `Body`.
   * @param recursive Currently not supported.
   */
  public inline function for_each_static(f:Body->Void, recursive:Bool = true) for (b in members) if (b.is_static()) f(cast b);
  /**
   * Clears the World's members and listeners.
   */
  public function clear() {
    clearing = true;
    while (members.length > 0) {
      var m = members.pop();
      if (m != null) m.remove();
    }
    clearing = false;
    reset_quadtrees();
    listeners.clear();
  }
  /**
   * Disposes the World. DO NOT use the World after disposing it, as it could lead to null reference errors.
   */
  public function dispose() {
    clearing = true;
    for_each(b -> b.remove());
    members = null;
    gravity = null;
    quadtree.put();
    listeners.dispose();
    listeners = null;
    history = null;
  }
  /**
   * Resets the World's dynamic and static Quadtrees.
   */
  public function reset_quadtrees() {
    init = true;
    // Carry over any tuned settings from the previous QuadTrees
    var max_depth = quadtree == null ? -1 : quadtree.max_depth;
    var max_contents = quadtree == null ? -1 : quadtree.max_contents;
    var static_max_depth = static_quadtree == null ? -1 : static_quadtree.max_depth;
    var static_max_contents = static_quadtree == null ? -1 : static_quadtree.max_contents;
    if (quadtree != null) quadtree.put();
    quadtree = QuadTree.get();
    if (static_quadtree != null) static_quadtree.put();
    static_quadtree = QuadTree.get();
    if (max_depth > -1) {
      quadtree.max_depth = max_depth;
      quadtree.max_contents = max_contents;
      static_quadtree.max_depth = static_max_depth;
      static_quadtree.max_contents = static_max_contents;
    }
    var r = center().to_aabb(true);
    quadtree.load(r);
    static_quadtree.load(r);
    for_each((member) -> {
      if (member.is_dynamic()) {
        member.dirty = true;
      }
      else {
        member.bounds(member.quadtree_data.bounds);
        static_quadtree.update(member.quadtree_data);
      }
    });
  }

  inline function get_count():Int return members.length;

  inline function set_x(value:Float) {
    x = value;
    if (init) reset_quadtrees();
    return x;
  }

  inline function set_y(value:Float) {
    y = value;
    if (init) reset_quadtrees();
    return y;
  }

  inline function set_width(value:Float) {
    width = value;
    if (init) reset_quadtrees();
    return height;
  }

  inline function set_height(value:Float) {
    height = value;
    if (init) reset_quadtrees();
    return height;
  }
}
