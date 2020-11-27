package echo.shape;

import echo.util.AABB;
import hxmath.frames.Frame2;
import echo.shape.*;
import echo.util.Pool;
import echo.data.Data;
import hxmath.math.Vector2;

using echo.util.SAT;
using echo.util.Ext;
using hxmath.math.MathUtil;

// TODO - extend Rect from Polygon to save on matrix calculations when syncing
class Rect extends Shape implements IPooled {
  public static var pool(get, never):IPool<Rect>;
  static var _pool = new Pool<Rect>(Rect);
  /**
   * The half-width of the Rectangle.
   */
  public var ex(default, set):Float;
  /**
   * The half-height of the Rectangle.
   */
  public var ey(default, set):Float;
  /**
   * The width of the Rectangle, transformed with `scale_x`. Use `local_width` to get the untransformed width.
   */
  public var width(get, set):Float;
  /**
   * The height of the Rectangle, transformed with `scale_y`. Use `local_height` to get the untransformed height.
   */
  public var height(get, set):Float;
  /**
   * The width of the Rectangle.
   */
  public var local_width(get, set):Float;
  /**
   * The height of the Rectangle.
   */
  public var local_height(get, set):Float;
  /**
   * The top-left position of the Rectangle.
   */
  public var min(get, null):Vector2;
  /**
   * The bottom-right position of the Rectangle.
   */
  public var max(get, null):Vector2;

  public var pooled:Bool;

  public var transformed_rect(default, null):Null<Polygon>;
  /**
   * Gets a Rect from the pool, or creates a new one if none are available. Call `put()` on the Rect to place it back in the pool.
   *
   * Note - The X and Y positions represent the center of the Rect. To set the Rect from its Top-Left origin, `Rect.get_from_min_max()` is available.
   * @param x The centered X position of the Rect.
   * @param y The centered Y position of the Rect.
   * @param width The width of the Rect.
   * @param height The height of the Rect.
   * @param rotation The rotation of the Rect.
   * @return Rect
   */
  public static inline function get(x:Float = 0, y:Float = 0, width:Float = 1, height:Float = 0, rotation:Float = 0, scale_x:Float = 1,
      scale_y:Float = 1):Rect {
    var rect = _pool.get();
    rect.set(x, y, width, height, rotation, scale_x, scale_y);
    rect.pooled = false;
    return rect;
  }
  /**
   * Gets a Rect from the pool, or creates a new one if none are available. Call `put()` on the Rect to place it back in the pool.
   * @param min_x
   * @param min_y
   * @param max_x
   * @param max_y
   * @return Rect
   */
  public static inline function get_from_min_max(min_x:Float, min_y:Float, max_x:Float, max_y:Float):Rect {
    var rect = _pool.get();
    rect.set_from_min_max(min_x, min_y, max_x, max_y);
    rect.pooled = false;
    return rect;
  }

  inline function new() {
    super();
    ex = 0;
    ey = 0;
    type = RECT;
  }

  override function put() {
    parent = null;
    if (transformed_rect != null) {
      transformed_rect.put();
      transformed_rect = null;
    }
    if (!pooled) {
      pooled = true;
      _pool.put_unsafe(this);
    }
  }

  public inline function set(x:Float = 0, y:Float = 0, width:Float = 1, height:Float = 0, rotation:Float = 0, scale_x:Float = 1, scale_y:Float = 1):Rect {
    local_x = x;
    local_y = y;
    local_width = width;
    local_height = height <= 0 ? width : height;
    local_rotation = rotation;
    local_scale_x = scale_x;
    local_scale_y = scale_y;
    return this;
  }

  public inline function set_from_min_max(min_x:Float, min_y:Float, max_x:Float, max_y:Float):Rect {
    return set((min_x + max_x) * 0.5, (min_y + max_y) * 0.5, max_x - min_x, max_y - min_y);
  }

  public inline function load(rect:Rect):Rect {
    local_x = rect.local_x;
    local_y = rect.local_y;
    ex = rect.ex;
    ey = rect.ey;
    local_rotation = rect.local_rotation;
    local_scale_x = rect.local_scale_x;
    local_scale_y = rect.local_scale_y;
    return this;
  }

  public function to_aabb(put_self:Bool = false):AABB {
    if (put_self) {
      var aabb = bounds();
      put();
      return aabb;
    }
    return bounds();
  }

  public function to_polygon(put_self:Bool = false):Polygon {
    if (put_self) {
      var polygon = Polygon.get_from_rect(this);
      put();
      return polygon;
    }
    return Polygon.get_from_rect(this);
  }

  override inline function bounds(?aabb:AABB):AABB {
    if (transformed_rect != null && rotation != 0) return transformed_rect.bounds(aabb);
    return (aabb == null) ? AABB.get(x, y, width, height) : aabb.set(x, y, width, height);
  }

  override inline function clone():Rect return Rect.get(local_x, local_y, width, height, local_rotation);

  override inline function contains(p:Vector2):Bool return this.rect_contains(p);

  @:dox(hide)
  @:deprecated("`intersect()` has been depricated - use `intersect_line()` or `intersect_ray()` instead.")
  override inline function intersect(l:Line):Null<IntersectionData> return this.rect_intersects_line(l);

  override function intersect_line(l:Line):Null<IntersectionData> return this.rect_intersects_line(l);

  override function intersect_ray(r:Ray):Null<IntersectionData> return this.rect_intersects_ray(r);

  override inline function overlaps(s:Shape):Bool {
    var cd = transformed_rect == null ? s.collides(this) : transformed_rect.collides(this);
    if (cd != null) {
      cd.put();
      return true;
    }
    return false;
  }

  override inline function collides(s:Shape):Null<CollisionData> return s.collide_rect(this);

  override inline function collide_rect(r:Rect):Null<CollisionData> return r.rect_and_rect(this);

  override inline function collide_circle(c:Circle):Null<CollisionData> return this.rect_and_circle(c);

  override inline function collide_polygon(p:Polygon):Null<CollisionData> return this.rect_and_polygon(p);

  override inline function transform() {
    if (transformed_rect == null && rotation != 0) {
      transformed_rect = Polygon.get_from_rect(this);
      transformed_rect.set_parent(parent);
    }
    else if (transformed_rect != null) transformed_rect.set_from_rect(this);
  }

  override function set_parent(?body:Body) {
    super.set_parent(body);
    if (transformed_rect != null) transformed_rect.set_parent(body);
  }

  // getters
  static function get_pool():IPool<Rect> return _pool;

  inline function get_width():Float return local_width * scale_x;

  inline function get_height():Float return local_height * scale_y;

  inline function get_local_width():Float return ex * 2;

  inline function get_local_height():Float return ey * 2;

  function get_min():Vector2 return new Vector2(left, top);

  function get_max():Vector2 return new Vector2(bottom, right);

  override inline function get_top():Float {
    if (transformed_rect == null || rotation == 0) return y - ey * scale_y;
    return transformed_rect.top;
  }

  override inline function get_bottom():Float {
    if (transformed_rect == null || rotation == 0) return y + ey * scale_y;
    return transformed_rect.bottom;
  }

  override inline function get_left():Float {
    if (transformed_rect == null || rotation == 0) return x - ex * scale_x;
    return transformed_rect.left;
  }

  override inline function get_right():Float {
    if (transformed_rect == null || rotation == 0) return x + ex * scale_x;
    return transformed_rect.right;
  }

  // setters
  inline function set_ex(value:Float):Float {
    ex = value;
    if (transformed_rect != null) transformed_rect.set_from_rect(this);
    return ex;
  }

  inline function set_ey(value:Float):Float {
    ey = value;
    if (transformed_rect != null) transformed_rect.set_from_rect(this);
    return ey;
  }

  inline function set_width(value:Float):Float {
    local_width = value / scale_x;
    return value;
  }

  inline function set_height(value:Float):Float {
    local_height = value / scale_y;
    return value;
  }

  inline function set_local_width(value:Float):Float return ex = value * 0.5;

  inline function set_local_height(value:Float):Float return ey = value * 0.5;
}
