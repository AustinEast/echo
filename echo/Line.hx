package echo;

import hxmath.math.MathUtil;
import echo.data.Data.IntersectionData;
import echo.util.Pool;
import echo.util.Proxy;
import hxmath.math.Vector2;

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
  public var pooled:Bool;

  public static inline function get(x:Float = 0, y:Float = 0, dx:Float = 1, dy:Float = 1):Line {
    var line = _pool.get();
    line.set(x, y, dx, dy);
    line.pooled = false;
    return line;
  }

  public static inline function get_from_vector(start:Vector2, angle:Float, length:Float) {
    var line = _pool.get();
    line.set_from_vector(start, angle, length);
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

  public inline function set_from_vector(start:Vector2, angle:Float, length:Float) {
    angle = MathUtil.degToRad(angle);
    var end = new Vector2(start.x + (length * Math.cos(angle)), start.y + (length * Math.sin(angle)));
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

  public inline function contains(v:Vector2):Bool {
    // Find the slope
    var m = (dy - y) / (dx - y);
    var b = y - m * x;
    return v.y == m * v.x + b;
  }

  public inline function intersect(shape:Shape):Null<IntersectionData> {
    return shape.intersect(this);
  }

  public inline function point_along_ratio(ratio:Float):Vector2 {
    return start - ratio * (start - end);
  }

  public inline function get_length() return start.distanceTo(end);

  static function get_pool():IPool<Line> return _pool;
}
