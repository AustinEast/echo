package echo.data;

import echo.util.Pool;
import echo.shape.Rect;
import hxmath.math.Vector2;

@:structInit
class WorldState {
  public var id:Int;
  public var x:Float;
  public var y:Float;
  public var rotation:Float;
  public var velocity:Vector2;

  public function new(id:Int, x:Float, y:Float, rotation:Float, velocity:Vector2) {
    this.id = id;
    this.x = x;
    this.y = y;
    this.rotation = rotation;
    this.velocity = velocity.clone();
  }
}

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
    c.data.resize(0);
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

  inline function new() data = [];

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

  public static inline function get(overlap:Float, x:Float, y:Float):CollisionData {
    var c = _pool.get();
    c.sa = null;
    c.sb = null;
    c.set(overlap, x, y);
    c.pooled = false;
    return c;
  }

  inline function new() normal = new Vector2(0, 0);

  public inline function set(overlap:Float, x:Float, y:Float) {
    this.overlap = overlap;
    normal.set(x, y);
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
