package echo.shape;

import echo.data.Data;
import echo.shape.*;
import echo.util.AABB;
import echo.util.Poolable;
import echo.math.Vector2;

using echo.util.SAT;

class Circle extends Shape implements Poolable {
  /**
   * The radius of the Circle, transformed with `scale_x`. Use `local_radius` to get the untransformed radius.
   */
  public var radius(get, set):Float;
  /**
   * The diameter of the Circle.
   */
  public var diameter(get, set):Float;
  /**
   * The local radius of the Circle, which represents the Circle's radius with no transformations.
   */
  public var local_radius:Float;
  /**
   * Gets a Cirlce from the pool, or creates a new one if none are available. Call `put()` on the Cirlce to place it back in the pool.
   * @param x
   * @param y
   * @param radius
   * @param rotation
   * @return Circle
   */
  public static inline function get(x:Float = 0, y:Float = 0, radius:Float = 1, rotation:Float = 0, scale_x:Float = 1, scale_y:Float = 1):Circle {
    var circle = pool.get();
    circle.set(x, y, radius, rotation, scale_x, scale_y);
    circle.pooled = false;
    return circle;
  }

  inline function new() {
    super();
    type = CIRCLE;
    radius = 0;
  }

  override function put() {
    super.put();
    if (!pooled) {
      pooled = true;
      pool.put_unsafe(this);
    }
  }

  public inline function set(x:Float = 0, y:Float = 0, radius:Float = 1, rotation:Float = 0, scale_x:Float = 1, scale_y:Float = 1):Circle {
    local_x = x;
    local_y = y;
    local_rotation = rotation;
    local_scale_x = scale_x;
    local_scale_y = scale_y;
    this.radius = radius;
    return this;
  }

  public inline function load(circle:Circle):Circle return set(circle.x, circle.y, circle.radius);

  override inline function bounds(?aabb:AABB):AABB {
    var d = diameter;
    return aabb == null ? AABB.get(x, y, d, d) : aabb.set(x, y, d, d);
  }

  override inline function volume():Float {
    var r = radius;
    return Math.PI * r * r;
  }

  override function clone():Circle return Circle.get(local_x, local_y, radius);

  override function contains(v:Vector2):Bool return this.circle_contains(v);

  override function intersect(l:Line):Null<IntersectionData> return this.circle_intersects(l);

  override inline function overlaps(s:Shape):Bool {
    var cd = s.collides(this);
    if (cd != null) {
      cd.put();
      return true;
    }
    return false;
  }

  override inline function collides(s:Shape):Null<CollisionData> return s.collide_circle(this, true);

  override inline function collide_rect(r:Rect, flip:Bool = false):Null<CollisionData> return r.rect_and_circle(this, !flip);

  override inline function collide_circle(c:Circle, flip:Bool = false):Null<CollisionData> return c.circle_and_circle(this, !flip);

  override inline function collide_polygon(p:Polygon, flip:Bool = false):Null<CollisionData> return this.circle_and_polygon(p, flip);

  // getters
  inline function get_radius():Float return local_radius * scale_x;

  inline function get_diameter():Float return radius * 2;

  override inline function get_top():Float return y - radius;

  override inline function get_bottom():Float return y + radius;

  override inline function get_left():Float return x - radius;

  override inline function get_right():Float return x + radius;

  // setters
  inline function set_radius(value:Float):Float {
    local_radius = value / scale_x;
    return value;
  }

  inline function set_diameter(value:Float):Float {
    radius = value * 0.5;
    return value;
  }
}
