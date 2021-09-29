package echo.math;

#if ECHO_USE_HXMATH
typedef Vector2Type = hxmath.math.Vector2;
typedef Vector3Type = hxmath.math.Vector3;
typedef Matrix3Type = hxmath.math.Matrix3x3;
#elseif ECHO_USE_ZEROLIB
typedef Vector2Type = zero.utilities.Vec2;
typedef Vector3Type = zero.utilities.Vec3;
typedef Matrix3Type = echo.math.Matrix3.Matrix3Default;
#elseif ECHO_USE_VECTORMATH
typedef Vector2Type = Vec2;
typedef Vector3Type = Vec3;
typedef Matrix3Type = echo.math.Matrix3.Matrix3Default;

// TODO - finish type once Mat3 elements are easily accessible
abstract Mat3Impl(Mat3) from Mat3 to Mat3 {
  // public var m00(get, set):Float;
  // public var m01(get, set):Float;
  // public var m02(get, set):Float;
  // public var m10(get, set):Float;
  // public var m11(get, set):Float;
  // public var m12(get, set):Float;
  // public var m20(get, set):Float;
  // public var m21(get, set):Float;
  // public var m22(get, set):Float;
  public inline function new(m00:Float, m10:Float, m20:Float, m01:Float, m11:Float, m21:Float, m02:Float, m12:Float, m22:Float) {
    this = new Mat3(m00, m01, m02, m10, m11, m12, m20, m21, m22);
  }
}
#elseif ECHO_USE_HEAPS
typedef Vector2Type = h2d.col.Point;
typedef Vector3Type = h3d.col.Point;
typedef Matrix3Type = echo.math.Matrix3.Matrix3Default;
#else
typedef Vector2Type = echo.math.Vector2.Vector2Default;
typedef Vector3Type = echo.math.Vector3.Vector3Default;
typedef Matrix3Type = echo.math.Matrix3.Matrix3Default;
#end
