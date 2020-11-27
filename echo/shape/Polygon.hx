package echo.shape;

import echo.util.AABB;
import hxmath.math.MathUtil;
import hxmath.frames.Frame2;
import echo.data.Data;
import echo.util.Pool;
import echo.shape.*;

using echo.util.SAT;
using hxmath.math.Vector2;
using hxmath.math.MathUtil;

class Polygon extends Shape implements IPooled {
  public static var pool(get, never):IPool<Polygon>;
  static var _pool = new Pool<Polygon>(Polygon);
  /**
   * The amount of vertices in the Polygon.
   */
  public var count(default, null):Int;
  /**
   * The Polygon's vertices adjusted for it's rotation.
   *
   * This Array represents a cache'd value, so changes to this Array will be overwritten.
   * Use `set_vertice()` or `set_vertices()` to edit this Polygon's vertices.
   */
  public var vertices(get, never):Array<Vector2>;
  /**
   * The Polygon's computed normals.
   *
   * This Array represents a cache'd value, so changes to this Array will be overwritten.
   * Use `set_vertice()` or `set_vertices()` to edit this Polygon's normals.
   */
  public var normals(get, never):Array<Vector2>;

  public var pooled:Bool;

  var local_frame:Frame2;

  var local_vertices:Array<Vector2>;

  var _vertices:Array<Vector2>;

  var _normals:Array<Vector2>;

  var _bounds:AABB;

  var dirty_vertices:Bool;

  var dirty_bounds:Bool;
  /**
   * Gets a Polygon from the pool, or creates a new one if none are available. Call `put()` on the Polygon to place it back in the pool.
   * @param x
   * @param y
   * @param sides
   * @param radius
   * @param rotation
   * @return Polygon
   */
  public static inline function get(x:Float = 0, y:Float = 0, sides:Int = 3, radius:Float = 1, rotation:Float = 0, scale_x:Float = 1,
      scale_y:Float = 1):Polygon {
    if (sides < 3) throw 'Polygons require 3 sides as a minimum';

    var polygon = _pool.get();

    var rot:Float = (Math.PI * 2) / sides;
    var angle:Float;
    var verts:Array<Vector2> = new Array<Vector2>();

    for (i in 0...sides) {
      angle = (i * rot) + ((Math.PI - rot) * 0.5);
      var vector:Vector2 = new Vector2(Math.cos(angle) * radius, Math.sin(angle) * radius);
      verts.push(vector);
    }

    polygon.set(x, y, rotation, verts, scale_x, scale_y);
    polygon.pooled = false;
    return polygon;
  }
  /**
   * Gets a Polygon from the pool, or creates a new one if none are available. Call `put()` on the Polygon to place it back in the pool.
   * @param x
   * @param y
   * @param rotation
   * @param vertices
   * @return Polygon
   */
  public static inline function get_from_vertices(x:Float = 0, y:Float = 0, rotation:Float = 0, ?vertices:Array<Vector2>, scale_x:Float = 1,
      scale_y:Float = 1):Polygon {
    var polygon = _pool.get();
    polygon.set(x, y, rotation, vertices, scale_x, scale_y);
    polygon.pooled = false;
    return polygon;
  }
  /**
   * Gets a Polygon from the pool, or creates a new one if none are available. Call `put()` on the Polygon to place it back in the pool.
   * @param rect
   * @return Polygon return _pool.get().set_from_rect(rect)
   */
  public static inline function get_from_rect(rect:Rect):Polygon return {
    var polygon = _pool.get();
    polygon.set_from_rect(rect);
    polygon.pooled = false;
    return polygon;
  }

  // TODO
  // public static inline function get_from_circle(c:Circle, sub_divisions:Int = 6) {}

  override inline function put() {
    parent = null;
    if (!pooled) {
      pooled = true;
      _pool.put_unsafe(this);
    }
  }

  public inline function set(x:Float = 0, y:Float = 0, rotation:Float = 0, ?vertices:Array<Vector2>, scale_x:Float = 1, scale_y:Float = 1):Polygon {
    lock_sync();
    local_x = x;
    local_y = y;
    local_rotation = rotation;
    local_scale_x = scale_x;
    local_scale_y = scale_y;
    set_vertices(vertices);
    unlock_sync();
    return this;
  }

  public inline function set_from_rect(rect:Rect):Polygon {
    count = 4;
    for (i in 0...count) if (local_vertices[i] == null) local_vertices[i] = new Vector2(0, 0);
    local_vertices[0].set(-rect.ex, -rect.ey);
    local_vertices[1].set(rect.ex, -rect.ey);
    local_vertices[2].set(rect.ex, rect.ey);
    local_vertices[3].set(-rect.ex, rect.ey);
    lock_sync();
    local_x = rect.local_x;
    local_y = rect.local_y;
    local_rotation = rect.local_rotation;
    local_scale_x = rect.local_scale_x;
    local_scale_y = rect.local_scale_y;
    dirty_vertices = true;
    dirty_bounds = true;
    unlock_sync();
    return this;
  }

  inline function new(?vertices:Array<Vector2>) {
    super();
    type = POLYGON;
    _vertices = [];
    _normals = [];
    _bounds = AABB.get();
    local_frame = new Frame2(new Vector2(0, 0), 0);
    set_vertices(vertices);
  }

  public inline function load(polygon:Polygon):Polygon return set(polygon.local_x, polygon.local_y, polygon.local_rotation, polygon.local_vertices,
    polygon.local_scale_x, polygon.local_scale_y);

  override function bounds(?aabb:AABB):AABB {
    if (dirty_bounds) {
      dirty_bounds = false;

      var left = vertices[0].x;
      var top = vertices[0].y;
      var right = vertices[0].x;
      var bottom = vertices[0].y;

      for (i in 1...count) {
        if (vertices[i].x < left) left = vertices[i].x;
        if (vertices[i].y < top) top = vertices[i].y;
        if (vertices[i].x > right) right = vertices[i].x;
        if (vertices[i].y > bottom) bottom = vertices[i].y;
      }

      _bounds.set_from_min_max(left, top, right, bottom);
    }

    return aabb == null ? _bounds.clone() : aabb.load(_bounds);
  }

  override function clone():Polygon return Polygon.get_from_vertices(x, y, rotation, local_vertices);

  override function contains(v:Vector2):Bool return this.polygon_contains(v);

  @:dox(hide)
  @:deprecated("`intersect()` has been depricated - use `intersect_line()` or `intersect_ray()` instead.")
  override function intersect(l:Line):Null<IntersectionData> return this.polygon_intersects_line(l);

  override function intersect_line(l:Line):Null<IntersectionData> return this.polygon_intersects_line(l);

  override function intersect_ray(r:Ray):Null<IntersectionData> return this.polygon_intersects_ray(r);

  override inline function overlaps(s:Shape):Bool {
    var cd = s.collides(this);
    if (cd != null) {
      cd.put();
      return true;
    }
    return false;
  }

  override inline function collides(s:Shape):Null<CollisionData> return s.collide_polygon(this);

  override inline function collide_rect(r:Rect):Null<CollisionData> return r.rect_and_polygon(this, true);

  override inline function collide_circle(c:Circle):Null<CollisionData> return c.circle_and_polygon(this);

  override inline function collide_polygon(p:Polygon):Null<CollisionData> return p.polygon_and_polygon(this, true);

  override inline function transform() {
    dirty_vertices = true;
    dirty_bounds = true;
  }

  override inline function get_top():Float {
    if (count == 0 || vertices[0] == null) return y;

    var top = vertices[0].y;
    for (i in 1...count) if (vertices[i].y < top) top = vertices[i].y;

    return top;
  }

  override inline function get_bottom():Float {
    if (count == 0 || vertices[0] == null) return y;

    var bottom = vertices[0].y;
    for (i in 1...count) if (vertices[i].y > bottom) bottom = vertices[i].y;

    return bottom;
  }

  override inline function get_left():Float {
    if (count == 0 || vertices[0] == null) return x;

    var left = vertices[0].x;
    for (i in 1...count) if (vertices[i].x < left) left = vertices[i].x;

    return left;
  }

  override inline function get_right():Float {
    if (count == 0 || vertices[0] == null) return x;

    var right = vertices[0].x;
    for (i in 1...count) if (vertices[i].x > right) right = vertices[i].x;

    return right;
  }

  // todo - Skip AABB
  public inline function to_rect():Rect return bounds().to_rect(true);
  /**
   * Sets the vertice at the desired index.
   * @param index
   * @param x
   * @param y
   */
  public inline function set_vertice(index:Int, x:Float = 0, y:Float = 0):Void {
    if (local_vertices[index] == null) local_vertices[index] = new Vector2(x, y);
    else local_vertices[index].set(x, y);

    dirty_vertices = true;
    dirty_bounds = true;
  }

  public inline function set_vertices(?vertices:Array<Vector2>, ?count:Int):Void {
    local_vertices = vertices == null ? [] : vertices;
    this.count = (count != null && count >= 0) ? count : local_vertices.length;
    if (count > local_vertices.length) for (i in local_vertices.length...count) local_vertices[i] = new Vector2(0, 0);

    dirty_vertices = true;
    dirty_bounds = true;
  }

  inline function transform_vertices():Void {
    local_frame.offset.set(local_x, local_y);
    local_frame.angleDegrees = local_rotation;

    // concat the parent frame, if possible
    if (parent != null) {
      local_frame.offset.x *= parent.scale_x;
      local_frame.offset.y *= parent.scale_y;
      var pos = (parent.frame.linearMatrix * local_frame.offset).addWith(parent.frame.offset);
      local_frame.angleDegrees = MathUtil.wrap(parent.frame.angleDegrees + local_frame.angleDegrees, 360);
      local_frame.offset.set(pos.x, pos.y);
    }

    // clear any extra vertices
    while (_vertices.length > count) _vertices.pop();

    for (i in 0...count) {
      if (local_vertices[i] == null) continue;
      if (_vertices[i] == null) _vertices[i] = new Vector2(0, 0);
      var pos = local_frame.transformFrom(new Vector2(local_vertices[i].x * scale_x, local_vertices[i].y * scale_y));
      _vertices[i].set(pos.x, pos.y);
    }
  }
  /**
   *  Compute face normals
   */
  inline function compute_normals():Void {
    for (i in 0...count) {
      _vertices[(i + 1) % count].copyTo(sync_pos);
      sync_pos.subtractWith(_vertices[i]);

      // Calculate normal with 2D cross product between vector and scalar
      if (_normals[i] == null) _normals[i] = new Vector2(-sync_pos.y, sync_pos.x);
      else _normals[i].set(-sync_pos.y, sync_pos.x);
      _normals[i].normalize();
    }
  }

  // getters
  static function get_pool():IPool<Polygon> return _pool;

  inline function get_vertices():Array<Vector2> {
    if (dirty_vertices) {
      dirty_vertices = false;
      transform_vertices();
      compute_normals();
    }

    return _vertices;
  }

  inline function get_normals():Array<Vector2> {
    if (dirty_vertices) {
      dirty_vertices = false;
      transform_vertices();
      compute_normals();
    }

    return _normals;
  }

  // setters
}
