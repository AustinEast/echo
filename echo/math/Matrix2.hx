package echo.math;

import echo.math.Types;

@:dox(hide)
@:noCompletion
class Matrix2Default {
  public var m00:Float;
  public var m01:Float;

  public var m10:Float;
  public var m11:Float;
  /**
   * Column-Major Orientation.
   * /m00, m10/
   * /m01, m11/
   */
  public inline function new(m00:Float, m10:Float, m01:Float, m11:Float) {
    this.m00 = m00 + 0.0;
    this.m10 = m10 + 0.0;
    this.m01 = m01 + 0.0;
    this.m11 = m11 + 0.0;
  }

  public function toString():String {
    return '{ m00:$m00, m10:$m10, m01:$m01, m11:$m11 }';
  }
}
/**
 * Column-Major Orientation.
 * /m00, m10/
 * /m01, m11/
 */
@:using(echo.math.Matrix2)
@:forward(m00, m10, m01, m11)
abstract Matrix2(Matrix2Type) from Matrix2Type to Matrix2Type {
  public static inline final element_count:Int = 4;

  public static var zero(get, never):Matrix2;

  public static var identity(get, never):Matrix2;

  public var col_x(get, set):Vector2;

  public var col_y(get, set):Vector2;
  /**
   * Gets a rotation matrix from the given radians.
   */
  public static inline function from_radians(radians:Float) {
    var c = Math.cos(radians);
    var s = Math.sin(radians);
    return new Matrix2(c, -s, s, c);
  }

  public static inline function from_vectors(x:Vector2, y:Vector2) return new Matrix2(x.x, y.x, x.y, y.y);

  @:from
  public static inline function from_arr(a:Array<Float>):Matrix2 @:privateAccess return new Matrix2(a[0], a[1], a[2], a[3]);

  @:to
  public inline function to_arr():Array<Float> {
    var self = this;
    return [self.m00, self.m10, self.m01, self.m11];
  }

  public inline function new(m00:Float, m10:Float, m01:Float, m11:Float) {
    this = new Matrix2Type(m00, m10, m01, m11);
  }

  // region operator overloads

  @:op([])
  public inline function arr_read(i:Int):Float {
    var self:Matrix2 = this;

    switch (i) {
      case 0:
        return self.m00;
      case 1:
        return self.m10;
      case 2:
        return self.m01;
      case 3:
        return self.m11;
      default:
        throw "Invalid element";
    }
  }

  @:op([])
  public inline function arr_write(i:Int, value:Float):Float {
    var self:Matrix2 = this;

    switch (i) {
      case 0:
        return self.m00 = value;
      case 1:
        return self.m10 = value;
      case 2:
        return self.m01 = value;
      case 3:
        return self.m11 = value;
      default:
        throw "Invalid element";
    }
  }

  @:op(a * b)
  static inline function mul(a:Matrix2, b:Matrix2):Matrix2
    return new Matrix2(a.m00 * b.m00
      + a.m10 * b.m01, a.m00 * b.m10
      + a.m10 * b.m11, a.m01 * b.m00
      + a.m11 * b.m01, a.m01 * b.m10
      + a.m11 * b.m11);

  @:op(a * b)
  static inline function mul_vec2(a:Matrix2, v:Vector2):Vector2
    return new Vector2(a.m00 * v.x + a.m10 * v.y, a.m01 * v.x + a.m11 * v.y);

  // endregion

  static inline function get_zero():Matrix2 {
    return new Matrix2(0.0, 0.0, 0.0, 0.0);
  }

  static inline function get_identity():Matrix2 {
    return new Matrix2(1.0, 0.0, 0.0, 1.0);
  }

  inline function get_col_x():Vector2 {
    var self = this;
    return new Vector2(self.m00, self.m01);
  }

  inline function get_col_y():Vector2 {
    var self = this;
    return new Vector2(self.m11, self.m11);
  }

  inline function set_col_x(vector2:Vector2):Vector2 {
    var self = this;
    return vector2.set(self.m00, self.m01);
  }

  inline function set_col_y(vector2:Vector2):Vector2 {
    var self = this;
    return vector2.set(self.m10, self.m11);
  }
}

inline function copy_to(a:Matrix2, b:Matrix2):Matrix2 {
  b.copy_from(a);
  return a;
}

inline function copy_from(a:Matrix2, b:Matrix2):Matrix2 {
  a.m00 = b.m00;
  a.m10 = b.m10;
  a.m01 = b.m01;
  a.m11 = b.m11;
  return a;
}

inline function transposed(m:Matrix2):Matrix2 return new Matrix2(m.m00, m.m01, m.m10, m.m11);
