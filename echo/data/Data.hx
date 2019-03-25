package echo.data;

import ghost.Pool;
import echo.shape.Rect;
import hxmath.math.Vector2;

class Collision implements IPooled {
  public static var pool(get, never):IPool<Collision>;
  static var _pool = new Pool<Collision>(Collision);
  /**
   * Body A.
   */
  public var a:Body;
  /**
   * Body B.
   */
  public var b:Body;
  /**
   * Array containing Data from Each Collision found between the two Bodies' Shapes.
   */
  public var data:Array<CollisionData>;
  public var pooled:Bool;

  public static inline function get(a:Body, b:Body):Collision {
    var c = _pool.get();
    c.a = a;
    c.b = b;
    c.data = [];
    c.pooled = false;
    return c;
  }

  public function put() {
    if (!pooled) {
      for (d in data) d.put();
      pooled = true;
      _pool.put_unsafe(this);
    }
  }

  static function get_pool():IPool<Collision> return _pool;
}

class CollisionData implements IPooled {
  public static var pool(get, never):IPool<CollisionData>;
  static var _pool = new Pool<CollisionData>(CollisionData);
  /**
   * Shape A.
   */
  public var sa:Shape;
  /**
   * Shape B.
   */
  public var sb:Shape;
  /**
   * The length of Shape A's penetration into Shape B.
   */
  public var overlap:Float;
  /**
   * The normal vector (direction) of Shape A's penetration into Shape B.
   */
  public var normal:Vector2;
  public var pooled:Bool;

  public static inline function get(overlap:Float, normal:Vector2):CollisionData {
    var c = _pool.get();
    c.overlap = overlap;
    c.normal = normal;
    c.pooled = false;
    return c;
  }

  public function put() {
    if (!pooled) {
      pooled = true;
      _pool.put_unsafe(this);
    }
  }

  static function get_pool():IPool<CollisionData> return _pool;
}

typedef IntersectionData = {}

typedef QuadTreeData = {
  /**
   * Id of the Data.
   */
  var id:Int;
  /**
   * Bounds of the Data.
   */
  var ?bounds:Rect;
  /**
   * Helper flag to check if this Data has been counted during queries.
   */
  var flag:Bool;
}

@:enum
abstract Direction(Int) from Int to Int {
  var TOP = 0;
}
