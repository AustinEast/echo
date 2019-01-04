package echo.shape;

import glib.Pool;
import echo.shape.*;
import hxmath.math.Vector2;

using echo.Collisions;

typedef CircleType = {
  var x:Float;
  var y:Float;
  var radius:Float;
}

class Circle extends Shape implements IPooled {
  public static var pool(get, never):IPool<Circle>;
  static var _pool = new Pool<Circle>(Circle);

  public var radius:Float;
  public var diameter(get, set):Float;
  public var pooled:Bool;

  public static inline function get(x:Float = 0, y:Float = 0, radius:Float = 1):Circle {
    var circle = _pool.get();
    circle.set(x, y, radius);
    circle.pooled = false;
    return circle;
  }

  function new() {
    super();
    type = CIRCLE;
    radius = 0;
  }

  override inline function put() {
    if (!pooled) {
      pooled = true;
      _pool.put_unsafe(this);
    }
  }

  public inline function set(x:Float = 0, y:Float = 0, radius:Float = 1):Circle {
    position.set(x, y);
    this.radius = radius;
    return this;
  }

  public inline function load(circle:Circle):Circle return set(circle.x, circle.y, circle.radius);

  override inline function to_aabb(?rect:Rect):Rect return rect == null ? Rect.get(x, y, diameter, diameter) : rect.set(x, y, diameter, diameter);

  override function clone():Circle return Circle.get(x, y, radius);

  override function contains(v:Vector2):Bool return this.circle_contains(v);

  override function intersects(l:Line):Null<IntersectionData> return this.circle_intersects(l);

  override inline function overlaps(s:Shape):Bool return s.collides(this) != null;

  override inline function collides(s:Shape):Null<CollisionData> return s.collide_circle(this);

  override inline function collide_rect(r:Rect):Null<CollisionData> return r.rect_and_circle(this, true);

  override inline function collide_circle(c:Circle):Null<CollisionData> return c.circle_and_circle(this);

  // getters
  static function get_pool():IPool<Circle> return _pool;

  inline function get_diameter():Float return radius * 2;

  override inline function get_top():Float return y - radius;

  override inline function get_bottom():Float return y + radius;

  override inline function get_left():Float return x - radius;

  override inline function get_right():Float return x + radius;

  // setters
  inline function set_diameter(value:Float):Float {
    radius = value * 0.5;
    return value;
  }
}
