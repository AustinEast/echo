package echo;

import echo.data.Data.IntersectionData;
import echo.util.AABB;
import echo.util.Poolable;
import echo.math.Vector2;

using echo.util.ext.FloatExt;

/**
 * A Ray has a starting point and a direction, but no end point - it extends endlessly (or up to `max_distance`, if set).
 *
 * Rays are cast with `Echo.raycast()` / `Echo.raycast_all()` (also available as `ray.raycast()` / `ray.raycast_all()`). Casting clips the Ray to the
 * bounds of whatever is being tested and then casts the resulting `Line`, so the `Intersection` results are the same as a Linecast's. Use a `Line`
 * instead when a finite segment with a known end point is needed.
 */
@:using(echo.Echo)
class Ray implements Poolable {
  /**
   * The Ray's starting position.
   */
  public var start(default, null):Vector2;
  /**
   * The Ray's direction. Always normalized - use `set_direction()` to change it.
   */
  public var direction(default, null):Vector2;
  /**
   * The Ray's angle, in radians.
   */
  public var radians(get, set):Float;
  /**
   * The Ray's angle, in degrees.
   */
  public var degrees(get, set):Float;
  /**
   * The furthest distance from `start` that the Ray reaches. If set to `0`, the Ray has no length limit.
   */
  public var max_distance:Float = 0;
  /**
   * `Line` reused for casting the clipped Ray against Shapes. Any `IntersectionData` produced by this Ray references it (as `data.line`), so it stays
   * valid until the Ray is clipped or cast again.
   */
  public var line(default, null):Line;
  /**
   * Gets a Ray from the pool, or creates a new one if none are available. Call `put()` on the Ray to place it back in the pool.
   * @param x The X position the Ray starts from.
   * @param y The Y position the Ray starts from.
   * @param direction_x The X component of the Ray's direction (normalized automatically).
   * @param direction_y The Y component of the Ray's direction (normalized automatically).
   * @param max_distance The furthest distance the Ray reaches. `0` means no limit.
   */
  public static inline function get(x:Float = 0, y:Float = 0, direction_x:Float = 1, direction_y:Float = 0, max_distance:Float = 0):Ray {
    var ray = pool.get();
    ray.set(x, y, direction_x, direction_y, max_distance);
    ray.pooled = false;
    return ray;
  }
  /**
   * Gets a Ray with the defined start point and angle (in degrees).
   * @param start A Vector2 describing the starting position of the Ray.
   * @param degrees The angle of the Ray (in degrees).
   * @param max_distance The furthest distance the Ray reaches. `0` means no limit.
   */
  public static inline function get_from_vector(start:Vector2, degrees:Float, max_distance:Float = 0):Ray {
    var ray = pool.get();
    ray.set_from_vector(start, degrees, max_distance);
    ray.pooled = false;
    return ray;
  }
  /**
   * Gets a Ray that starts at `start` and points towards `target`.
   * @param max_distance The furthest distance the Ray reaches. `0` means no limit.
   */
  public static inline function get_from_vectors(start:Vector2, target:Vector2, max_distance:Float = 0):Ray {
    var ray = pool.get();
    ray.set_from_vectors(start, target, max_distance);
    ray.pooled = false;
    return ray;
  }
  /**
   * Gets a Ray that starts at the Line's start point and points along it.
   * @param endless If `true`, the Ray has no length limit. Otherwise it ends where the Line ends.
   */
  public static inline function get_from_line(line:Line, endless:Bool = true):Ray {
    var ray = pool.get();
    ray.set_from_line(line, endless);
    ray.pooled = false;
    return ray;
  }

  inline function new() {
    start = new Vector2(0, 0);
    direction = new Vector2(1, 0);
    line = Line.get();
  }

  public inline function set(x:Float = 0, y:Float = 0, direction_x:Float = 1, direction_y:Float = 0, max_distance:Float = 0):Ray {
    start.set(x, y);
    set_direction(direction_x, direction_y);
    this.max_distance = max_distance;
    return this;
  }
  /**
   * Sets the Ray's direction. The direction is normalized, so any length of vector can be passed in.
   */
  public inline function set_direction(x:Float, y:Float):Ray {
    direction.set(x, y);
    if (direction.length_sq == 0) direction.set(1, 0);
    else direction.normalize();
    return this;
  }
  /**
   * Sets the Ray with the defined start point and angle (in degrees).
   */
  public inline function set_from_vector(start:Vector2, degrees:Float, max_distance:Float = 0):Ray {
    var rad = degrees.deg_to_rad();
    return set(start.x, start.y, Math.cos(rad), Math.sin(rad), max_distance);
  }
  /**
   * Sets the Ray to start at `start` and point towards `target`.
   */
  public inline function set_from_vectors(start:Vector2, target:Vector2, max_distance:Float = 0):Ray {
    return set(start.x, start.y, target.x - start.x, target.y - start.y, max_distance);
  }
  /**
   * Sets the Ray to start at the Line's start point and point along it.
   * @param endless If `true`, the Ray has no length limit. Otherwise it ends where the Line ends.
   */
  public inline function set_from_line(line:Line, endless:Bool = true):Ray {
    return set(line.x, line.y, line.dx - line.x, line.dy - line.y, endless ? 0 : line.length);
  }

  public inline function put() {
    if (!pooled) {
      pooled = true;
      pool.put_unsafe(this);
    }
  }
  /**
   * Gets the position along the Ray at the specified distance from its start.
   */
  public inline function point_along(distance:Float):Vector2 {
    return new Vector2(start.x + direction.x * distance, start.y + direction.y * distance);
  }
  /**
   * Gets the distance along the Ray of the point's projection onto it.
   * @param clamp If `true`, the distance is clamped to the Ray's extent (never negative, and never past `max_distance` if one is set).
   */
  public inline function distance_of_point(point:Vector2, clamp:Bool = true):Float {
    var d = (point.x - start.x) * direction.x + (point.y - start.y) * direction.y;
    if (clamp) {
      if (d < 0) d = 0;
      if (max_distance > 0 && d > max_distance) d = max_distance;
    }
    return d;
  }
  /**
   * Projects the point onto the Ray.
   */
  public inline function project_point(point:Vector2, clamp:Bool = true):Vector2 {
    return point_along(distance_of_point(point, clamp));
  }
  /**
   * Clips the Ray to an `AABB`, returning the part of the Ray from `start` to where it exits the AABB as a `Line` - or `null` if the Ray never
   * enters the AABB (or the AABB is entirely behind the Ray, or further away than `max_distance`).
   *
   * The returned Line is the Ray's own `line`, which is reused by every clip and cast. Don't `put()` it.
   */
  public function clip(aabb:AABB):Null<Line> {
    var t_min = 0.;
    var t_max = max_distance > 0 ? max_distance : Math.POSITIVE_INFINITY;

    // Slab test on each axis to find where the Ray enters and leaves the AABB
    if (direction.x.equals(0)) {
      if (start.x < aabb.min_x || start.x > aabb.max_x) return null;
    }
    else {
      var inv = 1 / direction.x;
      var t1 = (aabb.min_x - start.x) * inv;
      var t2 = (aabb.max_x - start.x) * inv;
      if (t1 > t2) {
        var t = t1;
        t1 = t2;
        t2 = t;
      }
      if (t1 > t_min) t_min = t1;
      if (t2 < t_max) t_max = t2;
      if (t_min > t_max) return null;
    }
    if (direction.y.equals(0)) {
      if (start.y < aabb.min_y || start.y > aabb.max_y) return null;
    }
    else {
      var inv = 1 / direction.y;
      var t1 = (aabb.min_y - start.y) * inv;
      var t2 = (aabb.max_y - start.y) * inv;
      if (t1 > t2) {
        var t = t1;
        t1 = t2;
        t2 = t;
      }
      if (t1 > t_min) t_min = t1;
      if (t2 < t_max) t_max = t2;
      if (t_min > t_max) return null;
    }
    if (!Math.isFinite(t_max)) return null;

    // The Line always starts at the Ray's start, so that intersection distances are measured from it
    line.set(start.x, start.y, start.x + direction.x * t_max, start.y + direction.y * t_max);
    return line;
  }
  /**
   * Casts the Ray against a single Shape.
   * @return The Intersection Data, or `null` if the Ray misses the Shape.
   */
  public function intersect(shape:Shape):Null<IntersectionData> {
    var bounds = shape.bounds();
    var l = clip(bounds);
    bounds.put();
    if (l == null) return null;
    var result = l.intersect(shape);
    if (result != null) result.ray = this;
    return result;
  }

  inline function get_radians():Float return Math.atan2(direction.y, direction.x);

  inline function set_radians(value:Float):Float {
    direction.set(Math.cos(value), Math.sin(value));
    return value;
  }

  inline function get_degrees():Float return radians.rad_to_deg();

  inline function set_degrees(value:Float):Float {
    radians = value.deg_to_rad();
    return value;
  }

  function toString() return 'Ray: {start: $start, direction: $direction, max_distance: $max_distance}';
}
