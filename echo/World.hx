package echo;

import hxmath.math.Vector2;
import echo.util.Disposable;
import echo.util.QuadTree;
import echo.util.History;
import echo.Listener;
import echo.shape.Rect;
import echo.data.Data;
import echo.data.Options;
/**
 * A `World` is an Object representing the state of a Physics simulation and it configurations. 
 */
 @:using(echo.Echo)
class World implements IDisposable {
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
  public var quadtree:QuadTree;
  public var static_quadtree:QuadTree;
  public var listeners:Listeners;
  public var members:Array<Body>;
  public var count(get, never):Int;
  /**
   * The amount of iterations that occur each time the World is stepped. The higher the number, the more stable the Physics Simulation will be, at the cost of performance.
   */
  public var iterations:Int;
  public var history:Null<History<Array<BodyState>>>;
  var init:Bool;

  public function new(options:WorldOptions) {
    members = options.members == null ? [] : options.members;
    init = false;
    width = options.width < 1 ? throw("World must have a width of at least 1") : options.width;
    height = options.height < 1 ? throw("World must have a width of at least 1") : options.height;
    x = options.x == null ? 0 : options.x;
    y = options.y == null ? 0 : options.y;
    gravity = new Vector2(options.gravity_x == null ? 0 : options.gravity_x, options.gravity_y == null ? 0 : options.gravity_y);
    refresh();

    listeners = new Listeners(options.listeners);
    iterations = options.iterations == null ? 5 : options.iterations;
    if(options.history != null) history = new History(options.history);
  }

  public inline function set_from_shape(s:Shape) {
    x = s.left;
    y = s.top;
    width = s.right - x;
    height = s.bottom - y;
  }

  public inline function center(?rect:Rect):Rect {
    return rect != null ? rect.set(x + (width * 0.5), y + (height * 0.5), width, height) : Rect.get(x + (width * 0.5), y + (height * 0.5), width, height);
  }

  public function add(body:Body):Body {
    if (body.world == this) return body;
    if (body.world != null) body.remove();
    body.world = this;
    members.push(body);
    body.cache.quadtree_data = {id: body.id, bounds: body.bounds(), flag: false};
    body.is_static() ? static_quadtree.insert(body.cache.quadtree_data) : quadtree.insert(body.cache.quadtree_data);
    return body;
  }

  public function remove(body:Body):Body {
    quadtree.remove(body.cache.quadtree_data);
    static_quadtree.remove(body.cache.quadtree_data);
    members.remove(body);
    body.world = null;
    return body;
  }

  public inline function iterator():Iterator<Body> return members.iterator();

  public inline function dynamics():Array<Body> return members.filter(b -> return b.is_dynamic());

  public inline function statics():Array<Body> return members.filter(b -> return b.is_static());

  public inline function for_each(f:Body->Void, recursive:Bool = true) for (b in members) f(cast b);

  public inline function for_each_dynamic(f:Body->Void, recursive:Bool = true) for (b in members) if (b.is_dynamic()) f(cast b);

  public inline function for_each_static(f:Body->Void, recursive:Bool = true) for (b in members) if (b.is_static()) f(cast b);

  /**
   * Clears the World's members and listeners.
   */
  public function clear() {
    members.resize(0);
    refresh();
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

  public function refresh() {
    init = true;
    if (quadtree != null) quadtree.put();
    quadtree = QuadTree.get();
    if (static_quadtree != null) static_quadtree.put();
    static_quadtree = QuadTree.get();
    var r = center();
    quadtree.load(r);
    static_quadtree.load(r);
    r.put();
    for_each_static((member)-> {
      member.bounds(member.cache.quadtree_data.bounds);
      static_quadtree.update(member.cache.quadtree_data);
    });
  }

  inline function get_count():Int return members.length;

  inline function set_x(value:Float) {
    x = value;
    if (init) refresh();
    return x;
  }

  inline function set_y(value:Float) {
    y = value;
    if (init) refresh();
    return y;
  }

  inline function set_width(value:Float) {
    width = value;
    if (init) refresh();
    return height;
  }

  inline function set_height(value:Float) {
    height = value;
    if (init) refresh();
    return height;
  }
}
