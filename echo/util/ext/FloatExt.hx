package echo.util.ext;

/**
 * Checks if two Floats are "equal" within the margin of error defined by the `diff` argument.
 * @param a The first Float to check for equality.
 * @param b The first Float to check for equality.
 * @param diff The margin of error to check by.
 * @return returns true if the floats are equal (within the defined margin of error)
 */
inline function equals(a:Float, b:Float, diff:Float = 0.00001):Bool
  return Math.abs(a - b) <= diff;

inline function clamp(value:Float, min:Float, max:Float):Float {
  if (value < min) return min;
  else if (value > max) return max;
  else return value;
}
/**
 * Converts specified angle in radians to degrees.
 * @return angle in degrees (not normalized to 0...360)
 */
inline function rad_to_deg(rad:Float):Float
  return 180 / Math.PI * rad;
/**
 * Converts specified angle in degrees to radians.
 * @return angle in radians (not normalized to 0...Math.PI*2)
 */
inline function deg_to_rad(deg:Float):Float
  return Math.PI / 180 * deg;
