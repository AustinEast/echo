package echo.data;

import haxe.ds.Vector;
import echo.math.Vector2;
import echo.util.AABB;
import echo.util.Pool;

@:structInit
class BodyState {
  public final id:Int;
  public final x:Float;
  public final y:Float;
  public final rotation:Float;
  public final velocity_x:Float;
  public final velocity_y:Float;
  public final acceleration_x:Float;
  public final acceleration_y:Float;
  public final rotational_velocity:Float;

  public function new(id:Int, x:Float, y:Float, rotation:Float, velocity_x:Float, velocity_y:Float, acceleration_x:Float, acceleration_y:Float,
      rotational_velocity:Float) {
    this.id = id;
    this.x = x;
    this.y = y;
    this.rotation = rotation;
    this.velocity_x = velocity_x;
    this.velocity_y = velocity_y;
    this.acceleration_x = acceleration_x;
    this.acceleration_y = acceleration_y;
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
  public final data:Array<CollisionData> = [];

  public var pooled = false;

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

  inline function new() {}

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
  public var sa:Null<Shape>;
  /**
   * Shape B.
   */
  public var sb:Null<Shape>;
  /**
   * The length of Shape A's penetration into Shape B.
   */
  public var overlap = 0.;

  public var contact_count = 0;

  public final contacts = Vector.fromArrayCopy([Vector2.zero, Vector2.zero]);
  /**
   * The normal vector (direction) of Shape A's penetration into Shape B.
   */
  public final normal = Vector2.zero;

  public var pooled = false;

  public static inline function get(overlap:Float, x:Float, y:Float):CollisionData {
    var c = _pool.get();
    c.sa = null;
    c.sb = null;
    c.contact_count = 0;
    for (cc in c.contacts) cc.set(0, 0);
    c.set(overlap, x, y);
    c.pooled = false;
    return c;
  }

  inline function new() {}

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
  public var line:Null<Line>;
  /**
   * Body.
   */
  public var body:Null<Body>;
  /**
   * Array containing Data from Each Intersection found between the Line and each Shape in the Body.
   */
  public final data:Array<IntersectionData> = [];

  public var pooled = false;
  /**
   * Gets the IntersectionData that has the closest hit distance from the beginning of the Line.
   */
  public var closest(get, never):Null<IntersectionData>;

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

  inline function new() {}

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

  public var line:Null<Line>;
  public var shape:Null<Shape>;
  /**
   * The second Line in the Intersection. This is only set when intersecting two Lines.
   */
  public var line2:Null<Line>;
  /**
   * The position along the line where the line hit the shape.
   */
  public final hit = Vector2.zero;
  /**
   * The distance between the start of the line and the hit position.
   */
  public var distance = 0.;
  /**
   * The length of the line that has overlapped the shape.
   */
  public var overlap = 0.;
  /**
   * The normal vector (direction) of the Line's penetration into the Shape.
   */
  public final normal = Vector2.zero;
  /**
    Indicates if normal was inversed and usually occurs when Line penetrates into the Shape from the inside.
  **/
  public var inverse_normal = false;

  public var pooled = false;

  public static inline function get(distance:Float, overlap:Float, x:Float, y:Float, normal_x:Float, normal_y:Float,
      inverse_normal:Bool = false):IntersectionData {
    var i = _pool.get();
    i.line = null;
    i.shape = null;
    i.line2 = null;
    i.set(distance, overlap, x, y, normal_x, normal_y, inverse_normal);
    i.pooled = false;
    return i;
  }

  inline function new() {
    hit = new Vector2(0, 0);
    normal = new Vector2(0, 0);
  }

  public inline function set(distance:Float, overlap:Float, x:Float, y:Float, normal_x:Float, normal_y:Float, inverse_normal:Bool = false) {
    this.distance = distance;
    this.overlap = overlap;
    this.inverse_normal = inverse_normal;
    hit.set(x, y);
    normal.set(normal_x, normal_y);
  }

  public function put() {
    if (!pooled) {
      pooled = true;
      _pool.put_unsafe(this);
    }
  }

  static function get_pool():IPool<IntersectionData> return _pool;
}

@:structInit
class QuadTreeData {
  /**
   * Id of the Data.
   */
  public var id:Int;
  /**
   * Bounds of the Data.
   */
  public var bounds:Null<AABB> = null;
  /**
   * Helper flag to check if this Data has been counted during queries.
   */
  public var flag = false;
}

@:enum
abstract Direction(Int) from Int to Int {
  var TOP = 0;
}
