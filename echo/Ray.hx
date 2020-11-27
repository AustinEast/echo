package echo;

import echo.data.Data.IntersectionData;
import echo.util.Pool;
import echo.util.Proxy;
import hxmath.math.Vector2;

using hxmath.math.MathUtil;

@:using(echo.Echo)
class Ray implements IProxy implements IPooled {
  public static var pool(get, never):IPool<Ray>;
  static var _pool = new Pool<Ray>(Ray);

  @:alias(position.x)
  public var x:Float;
  @:alias(position.y)
  public var y:Float;
  public var position:Vector2;
  @:alias(normal.x)
  public var dx:Float;
  @:alias(normal.y)
  public var dy:Float;
  public var normal:Vector2;
  public var pooled:Bool;

  public static inline function get(x:Float = 0, y:Float = 0, dx:Float = 1, dy:Float = 0):Ray {
    var ray = _pool.get();
    ray.set(x, y, dx, dy);
    ray.pooled = false;
    return ray;
  }

  public static inline function get_from_vector(start:Vector2, angle:Float) {
    var ray = _pool.get();
    ray.set_from_vector(start, angle);
    ray.pooled = false;
    return ray;
  }

  public static inline function get_from_vectors(start:Vector2, end:Vector2) {
    return get(start.x, start.y, end.x, end.y);
  }

  inline function new(x:Float = 0, y:Float = 0, dx:Float = 1, dy:Float = 0) {
    position = new Vector2(x, y);
    normal = new Vector2(dx, dy);
  }

  public inline function set(x:Float = 0, y:Float = 0, dx:Float = 1, dy:Float = 0):Ray {
    position.set(x, y);
    normal.set(dx, dy);
    return this;
  }

  public function set_from_vector(position:Vector2, degrees:Float) {
    var rad = MathUtil.degToRad(degrees);
    var normal = Vector2.fromPolar(rad, 1);
    return set(position.x, position.y, normal.x, normal.y);
  }

  public inline function set_from_vectors(position:Vector2, normal:Vector2) {
    return set(position.x, position.y, normal.x, normal.y);
  }

  public inline function put() {
    if (!pooled) {
      pooled = true;
      _pool.put_unsafe(this);
    }
  }

  public inline function intersect(shape:Shape):Null<IntersectionData> {
    return shape.intersect_ray(this);
  }
  /**
   * Gets the normal on the side of the Ray the point is.
   */
  // public function side(point:Vector2, ?set:Vector2) {
  //   var rad = (dx - x) * (point.y - y) - (dy - y) * (point.x - x);
  //   var dir = start - end;
  //   var normal = set == null ? new Vector2(0, 0) : set;
  //   if (rad > 0) normal.set(dir.y, -dir.x);
  //   else normal.set(-dir.y, dir.x);
  //   return normal.normalize();
  // }

  function toString() return 'Ray: {position: $position, normal: $normal}';

  static function get_pool():IPool<Ray> return _pool;
}
