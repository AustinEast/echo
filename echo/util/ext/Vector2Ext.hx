package echo.util.ext;

import hxmath.math.Vector2;

using Math;
/**
 * Normalizes a `Vector2` (in place) to represent the closest cardinal direction (Up, Down, Left, or Right).
 * @param normal The `Vector2` to modify.
 * @return the modified `Vector2`
 */
inline function square_normal(normal:Vector2):Vector2 {
  var len = normal.length;
  var dot_x = normal * Vector2.xAxis;
  var dot_y = normal * Vector2.yAxis;
  if (dot_x.abs() > dot_y.abs()) dot_x > 0 ? normal.set(1, 0) : normal.set(-1, 0);
  else dot_y > 0 ? normal.set(0, 1) : normal.set(0, -1);
  normal.normalizeTo(len);
  return normal;
}
/**
 * Gets the arc tangent angle between two `Vector2`, in radians.
 * @param v 
 * @param o 
 * @return Float
 */
inline function angle_between(v:Vector2, o:Vector2):Float
  return Math.atan2(v.x * o.y - v.y * o.x, v.x * o.x + v.y * o.y);
/**
 * Gets the arc tangent angle between three `Vector2`, in radians.
 * @param v 
 * @param left
 * @param right
 * @return Float
 */
inline function angle_between_2(v:Vector2, left:Vector2, right:Vector2):Float
  return angle_between(left - v, right - v);
