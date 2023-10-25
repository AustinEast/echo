package echo.shape;

import echo.data.Data;
import echo.math.Vector2;
import echo.shape.*;
import echo.util.AABB;
import echo.util.Poolable;

using echo.util.SAT;

class Rect extends Shape implements Poolable {
  /**
   * The half-width of the Rectangle, transformed with `scale_x`. Use `local_ex` to get the untransformed extent.
   */
  public var ex(get, set):Float;
  /**
   * The half-height of the Rectangle, transformed with `scale_y`. Use `local_ey` to get the untransformed extent.
   */
  public var ey(get, set):Float;
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
   * The half-width of the Rectangle.
   */
  public var local_ex(default, set):Float;
  /**
   * The half-height of the Rectangle.
   */
  public var local_ey(default, set):Float;
  /**
   * The top-left position of the Rectangle.
   */
  public var min(get, null):Vector2;
  /**
   * The bottom-right position of the Rectangle.
   */
  public var max(get, null):Vector2;
  /**
   * If the Rectangle has a rotation, this Polygon is constructed to represent the transformed vertices of the Rectangle.
   */
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
    var rect = pool.get();
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
    var rect = pool.get();
    rect.set_from_min_max(min_x, min_y, max_x, max_y);
    rect.pooled = false;
    return rect;
  }

  inline function new() {
    super();
    local_ex = 0;
    local_ey = 0;
    type = RECT;
    transform.on_dirty = on_dirty;
  }

  override function put() {
    super.put();
    if (transformed_rect != null) {
      transformed_rect.put();
      transformed_rect = null;
    }
    if (!pooled) {
      pooled = true;
      pool.put_unsafe(this);
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
    set_dirty();
    return this;
  }

  public inline function set_from_min_max(min_x:Float, min_y:Float, max_x:Float, max_y:Float):Rect {
    return set((min_x + max_x) * 0.5, (min_y + max_y) * 0.5, max_x - min_x, max_y - min_y);
  }

  public inline function load(rect:Rect):Rect {
    local_x = rect.local_x;
    local_y = rect.local_y;
    local_ex = rect.local_ex;
    local_ey = rect.local_ey;
    local_rotation = rect.local_rotation;
    local_scale_x = rect.local_scale_x;
    local_scale_y = rect.local_scale_y;
    set_dirty();
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

  override inline function volume() return width * height;

  override inline function clone():Rect return Rect.get(local_x, local_y, width, height, local_rotation);

  override inline function contains(p:Vector2):Bool return this.rect_contains(p);

  override inline function intersect(l:Line):Null<IntersectionData> return this.rect_intersects(l);

  override inline function overlaps(s:Shape):Bool {
    var cd = transformed_rect == null ? s.collides(this) : transformed_rect.collides(this);
    if (cd != null) {
      cd.put();
      return true;
    }
    return false;
  }

  // collision calculated as s against this. So flip result
  override inline function collides(s:Shape):Null<CollisionData> return s.collide_rect(this, true);

  override inline function collide_rect(r:Rect, flip:Bool = false):Null<CollisionData> return this.rect_and_rect(r, flip);

  override inline function collide_circle(c:Circle, flip:Bool = false):Null<CollisionData> return this.rect_and_circle(c, flip);

  override inline function collide_polygon(p:Polygon, flip:Bool = false):Null<CollisionData> return this.rect_and_polygon(p, flip);

  override function set_parent(?body:Body) {
    super.set_parent(body);
    set_dirty();
    if (transformed_rect != null) transformed_rect.set_parent(body);
  }

  function on_dirty(t) {
    set_dirty();
  }

  inline function set_dirty() {
    if (transformed_rect == null && rotation != 0) {
      transformed_rect = Polygon.get_from_rect(this);
      transformed_rect.set_parent(parent);
    }
    else if (transformed_rect != null) {
      transformed_rect.local_x = local_x;
      transformed_rect.local_y = local_y;
      transformed_rect.local_rotation = local_rotation;
      transformed_rect.local_scale_x = local_scale_x;
      transformed_rect.local_scale_y = local_scale_y;
    }
  }

  // getters

  inline function get_width():Float return local_width * scale_x;

  inline function get_height():Float return local_height * scale_y;

  inline function get_ex():Float return local_ex * local_scale_x;

  inline function get_ey():Float return local_ey * local_scale_y;

  inline function get_local_width():Float return local_ex * 2;

  inline function get_local_height():Float return local_ey * 2;

  function get_min():Vector2 return new Vector2(left, top);

  function get_max():Vector2 return new Vector2(bottom, right);

  override inline function get_top():Float {
    if (transformed_rect == null || rotation == 0) return y - ey;
    return transformed_rect.top;
  }

  override inline function get_bottom():Float {
    if (transformed_rect == null || rotation == 0) return y + ey;
    return transformed_rect.bottom;
  }

  override inline function get_left():Float {
    if (transformed_rect == null || rotation == 0) return x - ex;
    return transformed_rect.left;
  }

  override inline function get_right():Float {
    if (transformed_rect == null || rotation == 0) return x + ex;
    return transformed_rect.right;
  }

  // setters
  inline function set_ex(value:Float):Float {
    local_ex = value / scale_x;
    return value;
  }

  inline function set_ey(value:Float):Float {
    local_ey = value / scale_y;
    return value;
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

  inline function set_local_ex(value:Float):Float {
    local_ex = value;
    if (transformed_rect != null) transformed_rect.set_from_rect(this);
    return local_ex;
  }

  inline function set_local_ey(value:Float):Float {
    local_ey = value;
    if (transformed_rect != null) transformed_rect.set_from_rect(this);
    return local_ey;
  }
}
