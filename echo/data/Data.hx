package echo.data;

import echo.util.Pool;
import echo.shape.Rect;
import hxmath.math.Vector2;

@:structInit
class BodyState {
  public final id:Int;
  public final x:Float;
  public final y:Float;
  public final rotation:Float;
  public final velocity:Vector2;
  public final acceleration:Vector2;
  public final rotational_velocity:Float;

  public function new(id:Int, x:Float, y:Float, rotation:Float, velocity:Vector2, acceleration:Vector2, rotational_velocity:Float) {
    this.id = id;
    this.x = x;
    this.y = y;
    this.rotation = rotation;
    this.velocity = velocity.clone();
    this.acceleration = velocity.clone();
    this.rotational_velocity = rotational_velocity;
  }
}
/**
 * Class containing data describing any Collisions between two Bodies.
 */
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
/**
 * Class containing data describing a Collision between two Shapes.
 */
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
/**
 * Class containing data describing any Intersections between a Line and a Body.
 */
class Intersection implements IPooled {
  public static var pool(get, never):IPool<Intersection>;
  static var _pool = new Pool<Intersection>(Intersection);
  /**
   * Line.
   */
  public var line:Line;
  /**
   * Body.
   */
  public var body:Body;
  /**
   * Array containing Data from Each Intersection found between the Line and each Shape in the Body.
   */
  public var data:Array<IntersectionData>;
  /**
   * Gets the IntersectionData that has the closest hit distance from the beginning of the Line.
   */
  public var closest(get, never):Null<IntersectionData>;

  public var pooled:Bool;

  public static inline function get(line:Line, body:Body):Intersection {
    var i = _pool.get();
    i.line = line;
    i.body = body;
    i.data.resize(0);
    i.pooled = false;
    return i;
  }

  public function put() {
    if (!pooled) {
      for (d in data) d.put();
      pooled = true;
      _pool.put_unsafe(this);
    }
  }

  inline function new() data = [];

  inline function get_closest():Null<IntersectionData> {
    if (data.length == 0) return null;
    if (data.length == 1) return data[0];

    var closest = data[0];
    for (i in 1...data.length) if (data[i] != null && data[i].distance < closest.distance) closest = data[i];
    return closest;
  }

  static function get_pool():IPool<Intersection> return _pool;
}
/**
 * Class containing data describing an Intersection between a Line and a Shape.
 */
class IntersectionData implements IPooled {
  public static var pool(get, never):IPool<IntersectionData>;
  static var _pool = new Pool<IntersectionData>(IntersectionData);

  public var line:Line;
  public var shape:Shape;
  /**
   * The position along the line where the line hit the shape.
   */
  public var hit:Vector2;
  /**
   * The distance between the start of the line and the hit position.
   */
  public var distance:Float;
  /**
   * The length of the line that has overlapped the shape.
   */
  public var overlap:Float;

  public var pooled:Bool;

  public static inline function get(distance:Float, overlap:Float, x:Float, y:Float):IntersectionData {
    var i = _pool.get();
    i.line = null;
    i.shape = null;
    i.set(distance, overlap, x, y);
    i.pooled = false;
    return i;
  }

  inline function new() hit = new Vector2(0, 0);

  public inline function set(distance:Float, overlap:Float, x:Float, y:Float) {
    this.distance = distance;
    this.overlap = overlap;
    hit.set(x, y);
  }

  public function put() {
    if (!pooled) {
      pooled = true;
      _pool.put_unsafe(this);
    }
  }

  static function get_pool():IPool<IntersectionData> return _pool;
}

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
