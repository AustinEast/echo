package echo;

import echo.data.Data.IntersectionData;
import echo.util.AABB;
import echo.util.Pool;
import echo.util.Proxy;
import hxmath.math.Vector2;

using echo.util.Ext;
using hxmath.math.MathUtil;

@:using(echo.Echo)
class Line implements IProxy implements IPooled {
  public static var pool(get, never):IPool<Line>;
  static var _pool = new Pool<Line>(Line);

  @:alias(start.x)
  public var x:Float;
  @:alias(start.y)
  public var y:Float;
  public var start:Vector2;
  @:alias(end.x)
  public var dx:Float;
  @:alias(end.y)
  public var dy:Float;
  public var end:Vector2;
  @:alias(start.distanceTo(end))
  public var length(get, never):Float;
  public var radians(get, never):Float;
  public var pooled:Bool;

  public static inline function get(x:Float = 0, y:Float = 0, dx:Float = 1, dy:Float = 1):Line {
    var line = _pool.get();
    line.set(x, y, dx, dy);
    line.pooled = false;
    return line;
  }
  /**
   * Gets a Line with the defined start point, angle (in degrees), and length.
   * @param start A Vector2 describing the starting position of the Line.
   * @param degrees The angle of the Line (in degrees).
   * @param length The length of the Line.
   */
  public static inline function get_from_vector(start:Vector2, degrees:Float, length:Float) {
    var line = _pool.get();
    line.set_from_vector(start, degrees, length);
    line.pooled = false;
    return line;
  }

  public static inline function get_from_vectors(start:Vector2, end:Vector2) {
    return get(start.x, start.y, end.x, end.y);
  }

  inline function new(x:Float = 0, y:Float = 0, dx:Float = 1, dy:Float = 1) {
    start = new Vector2(x, y);
    end = new Vector2(dx, dy);
  }

  public inline function set(x:Float = 0, y:Float = 0, dx:Float = 1, dy:Float = 1):Line {
    start.set(x, y);
    end.set(dx, dy);
    return this;
  }
  /**
   * Sets the Line with the defined start point, angle (in degrees), and length.
   * @param start A Vector2 describing the starting position of the Line.
   * @param degrees The angle of the Line (in degrees).
   * @param length The length of the Line.
   */
  public function set_from_vector(start:Vector2, degrees:Float, length:Float) {
    var rad = MathUtil.degToRad(degrees);
    var end = new Vector2(start.x + (length * Math.cos(rad)), start.y + (length * Math.sin(rad)));
    return set(start.x, start.y, end.x, end.y);
  }

  public inline function set_from_vectors(start:Vector2, end:Vector2) {
    return set(start.x, start.y, end.x, end.y);
  }

  public inline function put() {
    if (!pooled) {
      pooled = true;
      _pool.put_unsafe(this);
    }
  }

  public function contains(v:Vector2):Bool {
    // Find the slope
    var m = (dy - y) / (dx - y);
    var b = y - m * x;
    return v.y == m * v.x + b;
  }

  public inline function intersect(shape:Shape):Null<IntersectionData> {
    return shape.intersect(this);
  }
  /**
   * Gets a position on the `Line` at the specified ratio.
   * @param ratio The ratio from the Line's `start` and `end` points (expects a value between 0.0 and 1.0).
   * @return Vector2
   */
  public inline function point_along_ratio(ratio:Float):Vector2 {
    return start + ratio * (end - start);
  }

  public inline function ratio_of_point(point:Vector2, clamp:Bool = true):Float {
    var ab = end - start;
    var ap = point - start;
    var t = ((ab * ap) / ab.lengthSq);
    if (clamp) t = t.clamp(0, 1);
    return t;
  }

  public inline function project_point(point:Vector2, clamp:Bool = true):Vector2 {
    return point_along_ratio(ratio_of_point(point, clamp));
  }
  /**
   * Gets the Line's normal based on the relative position of the point.
   */
  public inline function side(point:Vector2, ?set:Vector2) {
    var rad = (dx - x) * (point.y - y) - (dy - y) * (point.x - x);
    var dir = start - end;
    var normal = set == null ? new Vector2(0, 0) : set;

    if (rad > 0) normal.set(dir.y, -dir.x);
    else normal.set(-dir.y, dir.x);
    return normal.normalize();
  }

  public inline function to_aabb(put_self:Bool = false) {
    if (put_self) {
      var aabb = bounds();
      put();
      return aabb;
    }
    return bounds();
  }

  public inline function bounds(?aabb:AABB) {
    var min_x = 0.;
    var min_y = 0.;
    var max_x = 0.;
    var max_y = 0.;
    if (x < dx) {
      min_x = x;
      max_x = dx;
    }
    else {
      min_x = dx;
      max_x = x;
    }
    if (y < dy) {
      min_y = y;
      max_y = dy;
    }
    else {
      min_y = dy;
      max_y = y;
    }

    if (min_x - max_x == 0) max_x += 1;
    if (min_y + max_y == 0) max_y += 1;

    return (aabb == null) ? AABB.get_from_min_max(min_x, min_y, max_x, max_y) : aabb.set_from_min_max(min_x, min_y, max_x, max_y);
  }

  inline function get_length() return start.distanceTo(end);

  inline function get_radians() return Math.atan2(dy - y, dx - x);

  public function set_length(l:Float):Float {
    var old = length;
    if (old > 0) l /= old;
    dx = x + (dx - x) * l;
    dy = y + (dy - y) * l;
    return l;
  }

  public function set_radians(r:Float):Float {
    var len = length;
    dx = x + Math.cos(r) * len;
    dy = y + Math.sin(r) * len;
    return r;
  }

  function toString() return 'Line: {start: $start, end: $end}';

  static function get_pool():IPool<Line> return _pool;
}
