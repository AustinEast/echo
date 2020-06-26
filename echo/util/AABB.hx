package echo.util;

import echo.shape.Rect;
import echo.util.Pool;

class AABB implements IPooled {
  public static var pool(get, never):IPool<AABB>;
  static var _pool = new Pool<AABB>(AABB);

  public var min_x:Float;
  public var max_x:Float;
  public var min_y:Float;
  public var max_y:Float;

  public var width(get, never):Float;
  public var height(get, never):Float;

  public var pooled:Bool;

  public static inline function get(x:Float = 0, y:Float = 0, width:Float = 1, height:Float = 0):AABB {
    var rect = _pool.get();
    rect.set(x, y, width, height);
    rect.pooled = false;
    return rect;
  }

  public static inline function get_from_min_max(min_x:Float, min_y:Float, max_x:Float, max_y:Float):AABB {
    var rect = _pool.get();
    rect.set_from_min_max(min_x, min_y, max_x, max_y);
    rect.pooled = false;
    return rect;
  }

  inline function new() {
    min_x = 0;
    max_x = 1;
    min_y = 0;
    max_y = 1;
  }

  public inline function set(x:Float = 0, y:Float = 0, width:Float = 1, height:Float = 1) {
    width *= 0.5;
    height *= 0.5;
    this.min_x = x - width;
    this.min_y = y - height;
    this.max_x = x + width;
    this.max_y = y + height;
    return this;
  }

  public inline function set_from_min_max(min_x:Float, min_y:Float, max_x:Float, max_y:Float) {
    this.min_x = min_x;
    this.max_x = max_x;
    this.min_y = min_y;
    this.max_y = max_y;
    return this;
  }

  public inline function to_rect(put_self:Bool = false):Rect {
    if (put_self) put();
    return Rect.get_from_min_max(min_x, min_y, max_x, max_y);
  }

  public inline function overlaps(other:AABB):Bool {
    return this.min_x < other.max_x && this.max_x >= other.min_x && this.min_y < other.max_y && this.max_y >= other.min_y;
  }

  public inline function load(rect:AABB) {
    this.min_x = rect.min_x;
    this.max_x = rect.max_x;
    this.min_y = rect.min_y;
    this.max_y = rect.max_y;
  }

  public function put() {
    if (!pooled) {
      pooled = true;
      _pool.put_unsafe(this);
    }
  }

  // getters
  static function get_pool():IPool<AABB> return _pool;

  inline function get_width():Float return max_x - min_x;

  inline function get_height():Float return max_y - min_y;
}
