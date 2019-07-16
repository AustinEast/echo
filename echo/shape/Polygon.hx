package echo.shape;

import echo.util.Pool;
import hxmath.math.Vector2;
import echo.shape.*;

using hxmath.math.MathUtil;
/**
 * TODO: EVERYTHING
 */
class Polygon extends Shape implements IPooled {
  public static var pool(get, never):IPool<Polygon>;
  static var _pool = new Pool<Polygon>(Polygon);

  public var vertices:Array<Vector2>;
  public var normals:Array<Vector2>;
  public var pooled:Bool;

  public static inline function get(x:Float = 0, y:Float = 0, ?vertices:Array<Vector2>):Polygon {
    var polygon = _pool.get();
    polygon.set(x, y, vertices);
    polygon.pooled = false;
    return polygon;
  }

  public static inline function from_rect() {}

  public static inline function from_circle(sub_divisions:Int = 3) {}

  override function put() {
    if (!pooled) {
      pooled = true;
      _pool.put_unsafe(this);
    }
  }

  public inline function set(x:Float = 0, y:Float = 0, ?vertices:Array<Vector2>):Polygon {
    position.set(x, y);
    vertices == null ? this.vertices.resize(0) : this.vertices = vertices;
    return this;
  }

  inline function new(?vertices:Array<Vector2>) {
    super();
    type = POLYGON;
    this.vertices = vertices == null ? [] : vertices;
  }

  public inline function to_rect():Rect return Rect.get(x, y);

  // getters
  static function get_pool():IPool<Polygon> return _pool;
}
