package echo.util;

import echo.shape.Rect;
import echo.util.Pool;
import hxmath.math.Vector2;

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
  /**
   * Gets an AABB from the pool, or creates a new one if none are available. Call `put()` on the AABB to place it back in the pool.
   *
   * Note - The X and Y positions represent the center of the AABB. To set the AABB from its Top-Left origin, `AABB.get_from_min_max()` is available.
   * @param x The centered X position of the AABB.
   * @param y The centered Y position of the AABB.
   * @param width The width of the AABB.
   * @param height The height of the AABB.
   * @return AABB
   */
  public static inline function get(x:Float = 0, y:Float = 0, width:Float = 1, height:Float = 1):AABB {
    var aabb = _pool.get();
    aabb.set(x, y, width, height);
    aabb.pooled = false;
    return aabb;
  }
  /**
   * Gets an AABB from the pool, or creates a new one if none are available. Call `put()` on the AABB to place it back in the pool.
   * @param min_x
   * @param min_y
   * @param max_x
   * @param max_y
   * @return AABB
   */
  public static inline function get_from_min_max(min_x:Float, min_y:Float, max_x:Float, max_y:Float):AABB {
    var aabb = _pool.get();
    aabb.set_from_min_max(min_x, min_y, max_x, max_y);
    aabb.pooled = false;
    return aabb;
  }

  inline function new() {
    min_x = 0;
    max_x = 1;
    min_y = 0;
    max_y = 1;
  }
  /**
   * Sets the values on this AABB.
   *
   * Note - The X and Y positions represent the center of the AABB. To set the AABB from its Top-Left origin, `AABB.set_from_min_max()` is available.
   * @param x The centered X position of the AABB.
   * @param y The centered Y position of the AABB.
   * @param width The width of the AABB.
   * @param height The height of the AABB.
   * @return AABB
   */
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

  public inline function contains(point:Vector2):Bool {
    return min_x <= point.x && max_x >= point.x && min_y <= point.y && max_y >= point.y;
  }

  public inline function load(aabb:AABB):AABB {
    this.min_x = aabb.min_x;
    this.max_x = aabb.max_x;
    this.min_y = aabb.min_y;
    this.max_y = aabb.max_y;
    return this;
  }
  /**
   * Adds the bounds of an AABB into this AABB.
   * @param aabb
   */
  public inline function add(aabb:AABB) {
    if (min_x > aabb.min_x) min_x = aabb.min_x;
    if (min_y > aabb.min_y) min_y = aabb.min_y;
    if (max_x < aabb.max_x) max_x = aabb.max_x;
    if (max_y < aabb.max_y) max_y = aabb.max_y;
  }

  public inline function clone() {
    return AABB.get_from_min_max(min_x, min_y, max_x, max_y);
  }

  public function put() {
    if (!pooled) {
      pooled = true;
      _pool.put_unsafe(this);
    }
  }

  function toString() return 'AABB: {min_x: $min_x, min_y: $min_y, max_x: $max_x, max_y: $max_y}';

  // getters
  static function get_pool():IPool<AABB> return _pool;

  inline function get_width():Float return max_x - min_x;

  inline function get_height():Float return max_y - min_y;
}
