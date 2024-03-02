package echo;

import echo.Listener;
import echo.data.Data;
import echo.data.Options;
import echo.shape.Rect;
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

  public var history:Null<History<Array<BodyState>>>;

  public var accumulatedTime:Float = 0;

  var init:Bool;

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
    body.quadtree_data = {id: body.id, bounds: body.bounds(), flag: false};
    body.is_static() ? static_quadtree.insert(body.quadtree_data) : quadtree.insert(body.quadtree_data);
    return body;
  }

  public function remove(body:Body):Body {
    quadtree.remove(body.quadtree_data);
    static_quadtree.remove(body.quadtree_data);
    members.remove(body);
    body.world = null;
    return body;
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
    while (members.length > 0) {
      var m = members.pop();
      if (m != null) m.remove();
    }
    reset_quadtrees();
    listeners.clear();
  }
  /**
   * Disposes the World. DO NOT use the World after disposing it, as it could lead to null reference errors.
   */
  public function dispose() {
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
    if (quadtree != null) quadtree.put();
    quadtree = QuadTree.get();
    if (static_quadtree != null) static_quadtree.put();
    static_quadtree = QuadTree.get();
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
