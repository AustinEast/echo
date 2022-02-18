package echo.math;

import echo.math.Types.Matrix3Type;

@:dox(hide)
@:noCompletion
class Matrix3Default {
  public var m00:Float;
  public var m01:Float;
  public var m02:Float;

  public var m10:Float;
  public var m11:Float;
  public var m12:Float;

  public var m20:Float;
  public var m21:Float;
  public var m22:Float;
  /**
   * /m00, m10, m20/
   * /m01, m11, m21/
   * /m02m m12, m22/
   */
  public inline function new(m00:Float, m10:Float, m20:Float, m01:Float, m11:Float, m21:Float, m02:Float, m12:Float, m22:Float) {
    this.m00 = m00 + 0.0;
    this.m10 = m10 + 0.0;
    this.m20 = m20 + 0.0;

    this.m01 = m01 + 0.0;
    this.m11 = m11 + 0.0;
    this.m21 = m21 + 0.0;

    this.m02 = m02 + 0.0;
    this.m12 = m12 + 0.0;
    this.m22 = m22 + 0.0;
  }

  public function toString():String {
    return '{ m00:$m00, m10:$m10, m20:$m20, m01:$m01, m11:$m11, m21:$m21, m02:$m02, m12:$m12, m22:$m22 }';
  }
}

@:using(echo.math.Matrix3)
@:forward(m00, m10, m20, m01, m11, m21, m02, m12, m22)
abstract Matrix3(Matrix3Type) from Matrix3Type to Matrix3Type {
  public static inline final element_count:Int = 9;

  public static var zero(get, never):Matrix3;

  public static var identity(get, never):Matrix3;

  @:from
  public static inline function from_arr(a:Array<Float>):Matrix3 @:privateAccess return new Matrix3(a[0], a[1], a[2], a[3], a[4], a[5], a[6], a[7], a[8]);

  @:to
  public inline function to_arr():Array<Float> {
    var self = this;
    return [
      self.m00,
      self.m10,
      self.m20,
      self.m01,
      self.m11,
      self.m21,
      self.m02,
      self.m12,
      self.m22
    ];
  }

  public inline function new(m00:Float, m10:Float, m20:Float, m01:Float, m11:Float, m21:Float, m02:Float, m12:Float, m22:Float) {
    this = new Matrix3Type(m00, m10, m20, m01, m11, m21, m02, m12, m22);
  }

  // region operator overloads

  @:op([])
  public inline function arr_read(i:Int):Float {
    var self:Matrix3 = this;

    switch (i) {
      case 0:
        return self.m00;
      case 1:
        return self.m10;
      case 2:
        return self.m20;
      case 3:
        return self.m01;
      case 4:
        return self.m11;
      case 5:
        return self.m21;
      case 6:
        return self.m02;
      case 7:
        return self.m12;
      case 8:
        return self.m22;
      default:
        throw "Invalid element";
    }
  }

  @:op([])
  public inline function arr_write(i:Int, value:Float):Float {
    var self:Matrix3 = this;

    switch (i) {
      case 0:
        return self.m00 = value;
      case 1:
        return self.m10 = value;
      case 2:
        return self.m20 = value;
      case 3:
        return self.m01 = value;
      case 4:
        return self.m11 = value;
      case 5:
        return self.m21 = value;
      case 6:
        return self.m02 = value;
      case 7:
        return self.m12 = value;
      case 8:
        return self.m22 = value;
      default:
        throw "Invalid element";
    }
  }

  @:op(a * b)
  static inline function mul(a:Matrix3, b:Matrix3):Matrix3 {
    return new Matrix3(a.m00 * b.m00
      + a.m10 * b.m01
      + a.m20 * b.m02, a.m00 * b.m10
      + a.m10 * b.m11
      + a.m20 * b.m12,
      a.m00 * b.m20
      + a.m10 * b.m21
      + a.m20 * b.m22, a.m01 * b.m00

      + a.m11 * b.m01
      + a.m21 * b.m02, a.m01 * b.m10
      + a.m11 * b.m11
      + a.m21 * b.m12,
      a.m01 * b.m20
      + a.m11 * b.m21
      + a.m21 * b.m22, a.m02 * b.m00

      + a.m12 * b.m01
      + a.m22 * b.m02, a.m02 * b.m10
      + a.m12 * b.m11
      + a.m22 * b.m12,
      a.m02 * b.m20
      + a.m12 * b.m21
      + a.m22 * b.m22);
  }

  @:op(a * b)
  static inline function mul_vec3(a:Matrix3, v:Vector3):Vector3 {
    return new Vector3(a.m00 * v.x
      + a.m10 * v.y
      + a.m20 * v.z, a.m01 * v.x
      + a.m11 * v.y
      + a.m21 * v.z, a.m02 * v.x
      + a.m12 * v.y
      + a.m22 * v.z);
  }

  // endregion

  static inline function get_zero():Matrix3 {
    return new Matrix3(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
  }

  static inline function get_identity():Matrix3 {
    return new Matrix3(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0);
  }

  public inline function copy_to(b:Matrix3):Matrix3 {
    var a = this;
    b.copy_from(a);
    return a;
  }

  public inline function copy_from(b:Matrix3):Matrix3 {
    var a = this;
    a.m00 = b.m00;
    a.m10 = b.m10;
    a.m20 = b.m20;

    a.m01 = b.m01;
    a.m11 = b.m11;
    a.m21 = b.m21;

    a.m02 = b.m02;
    a.m12 = b.m12;
    a.m22 = b.m22;
    return a;
  }
}
