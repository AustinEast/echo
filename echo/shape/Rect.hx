package echo.shape;

import hxmath.frames.Frame2;
import echo.shape.*;
import echo.util.Pool;
import echo.data.Data;
import hxmath.math.Vector2;

using echo.util.SAT;
using echo.util.Ext;
using hxmath.math.MathUtil;

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
   * The width of the Rectangle.
   */
  public var width(get, set):Float;
  /**
   * The height of the Rectangle.
   */
  public var height(get, set):Float;
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

  public static inline function get(x:Float = 0, y:Float = 0, width:Float = 1, height:Float = 0, rotation:Float = 0):Rect {
    var rect = _pool.get();
    rect.set(x, y, width, height, rotation);
    rect.pooled = false;
    return rect;
  }

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
    parent_frame = null;
    if (transformed_rect != null) {
      transformed_rect.put();
      transformed_rect = null;
    }
    if (!pooled) {
      pooled = true;
      _pool.put_unsafe(this);
    }
  }

  public inline function set(x:Float = 0, y:Float = 0, width:Float = 1, height:Float = 0, rotation:Float = 0):Rect {
    this.local_x = x;
    this.local_y = y;
    this.width = width;
    this.height = height <= 0 ? width : height;
    this.local_rotation = rotation;
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
    return this;
  }

  override inline function bounds(?rect:Rect):Rect {
    if (transformed_rect != null) return transformed_rect.bounds(rect);
    return (rect == null) ? Rect.get(x, y, width, height) : rect.set(x, y, width, height);
  }

  override inline function clone():Rect return Rect.get(local_x, local_y, width, height, local_rotation);

  override inline function contains(p:Vector2):Bool return this.rect_contains(p);

  override inline function intersects(l:Line):Null<IntersectionData> return this.rect_intersects(l);

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

  override inline function sync() {
    if (parent_frame != null) {
      var pos = parent_frame.transformFrom(get_local_position());
      _x = pos.x;
      _y = pos.y;
      _rotation = parent_frame.angleDegrees.degToRad() + local_rotation;
    }
    else {
      _x = local_x;
      _y = local_x;
      _rotation = local_rotation;
    }

    if (transformed_rect == null && !rotation.equals(0)) transformed_rect = Polygon.get_from_rect(this);
    else if (transformed_rect != null) transformed_rect.set_from_rect(this);
  }

  // getters
  static function get_pool():IPool<Rect> return _pool;

  inline function get_width():Float return ex * 2;

  inline function get_height():Float return ey * 2;

  function get_min():Vector2 return new Vector2(left, top);

  function get_max():Vector2 return new Vector2(bottom, right);

  override inline function get_top():Float {
    if (transformed_rect == null) return y - ey;
    return transformed_rect.top;
  }

  override inline function get_bottom():Float {
    if (transformed_rect == null) return y + ey;
    return transformed_rect.bottom;
  }

  override inline function get_left():Float {
    if (transformed_rect == null) return x - ex;
    return transformed_rect.left;
  }

  override inline function get_right():Float {
    if (transformed_rect == null) return x + ex;
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

  inline function set_width(value:Float):Float return ex = value * 0.5;

  inline function set_height(value:Float):Float return ey = value * 0.5;
}
