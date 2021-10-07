package echo.math;

import echo.math.Types.Vector2Type;

using Math;

@:dox(hide)
@:noCompletion
class Vector2Default {
  public var x:Float;
  public var y:Float;

  public inline function new(x:Float, y:Float) {
    // the + 0.0 helps the optimizer realize it can collapse const float operations (from vector-math lib)
    this.x = x + 0.0;
    this.y = y + 0.0;
  }

  public function toString():String
    return '{ x:$x, y:$y }';
}

@:using(echo.math.Vector2)
@:forward(x, y)
abstract Vector2(Vector2Type) from Vector2Type to Vector2Type {
  public static var zero(get, never):Vector2;
  public static var up(get, never):Vector2;
  public static var down(get, never):Vector2;
  public static var right(get, never):Vector2;
  public static var left(get, never):Vector2;

  public var length(get, set):Float;

  public var length_sq(get, never):Float;

  public var radians(get, set):Float;

  public var normal(get, never):Vector2;

  public static inline function from_radians(radians:Float, radius:Float):Vector2
    return new Vector2(radius * Math.cos(radians), radius * Math.sin(radians));

  @:from
  public static inline function from_arr(a:Array<Float>):Vector2
    return new Vector2(a[0], a[1]);

  @:to
  public inline function to_arr():Array<Float> {
    var self = this;
    return [self.x, self.y];
  }

  public inline function new(x:Float, y:Float) @:privateAccess this = new Vector2Type(x, y);

  // region operator overloads

  @:op([])
  inline function arr_read(i:Int) {
    var self = this;
    return switch i {
      case 0: self.x;
      case 1: self.y;
      default: throw "Invalid element";
    }
  }

  @:op([])
  inline function arr_write(i:Int, v:Float) {
    var self = this;
    return switch i {
      case 0: self.x = v;
      case 1: self.y = v;
      default: throw "Invalid element";
    }
  }

  @:op(-a)
  static inline function neg(a:Vector2)
    return new Vector2(-a.x, -a.y);

  @:op(++a)
  static inline function prefix_increment(a:Vector2) {
    ++a.x;
    ++a.y;
    return a.clone();
  }

  @:op(--a)
  static inline function prefix_decrement(a:Vector2) {
    --a.x;
    --a.y;
    return a.clone();
  }

  @:op(a++)
  static inline function postfix_increment(a:Vector2) {
    var ret = a.clone();
    ++a.x;
    ++a.y;
    return ret;
  }

  @:op(a--)
  static inline function postfix_decrement(a:Vector2) {
    var ret = a.clone();
    --a.x;
    --a.y;
    return ret;
  }

  @:op(a * b)
  static inline function mul(a:Vector2, b:Vector2):Vector2
    return new Vector2(a.x * b.x, a.y * b.y);

  @:op(a * b) @:commutative
  static inline function mul_scalar(a:Vector2, b:Float):Vector2
    return new Vector2(a.x * b, a.y * b);

  @:op(a / b)
  static inline function div(a:Vector2, b:Vector2):Vector2
    return new Vector2(a.x / b.x, a.y / b.y);

  @:op(a / b)
  static inline function div_scalar(a:Vector2, b:Float):Vector2
    return new Vector2(a.x / b, a.y / b);

  @:op(a / b)
  static inline function div_scalar_inv(a:Float, b:Vector2):Vector2
    return new Vector2(a / b.x, a / b.y);

  @:op(a + b)
  static inline function add(a:Vector2, b:Vector2):Vector2
    return new Vector2(a.x + b.x, a.y + b.y);

  @:op(a + b) @:commutative
  static inline function add_scalar(a:Vector2, b:Float):Vector2
    return new Vector2(a.x + b, a.y + b);

  @:op(a - b)
  static inline function sub(a:Vector2, b:Vector2):Vector2
    return new Vector2(a.x - b.x, a.y - b.y);

  @:op(a - b)
  static inline function sub_scalar(a:Vector2, b:Float):Vector2
    return new Vector2(a.x - b, a.y - b);

  @:op(b - a)
  static inline function sub_scalar_inv(a:Float, b:Vector2):Vector2
    return new Vector2(a - b.x, a - b.y);

  @:op(a == b)
  static inline function equal(a:Vector2, b:Vector2):Bool
    return a.x == b.x && a.y == b.y;

  @:op(a != b)
  static inline function not_equal(a:Vector2, b:Vector2):Bool
    return !equal(a, b);

  @:op(a *= b)
  static inline function mul_eq(a:Vector2, b:Vector2):Vector2
    return a.copy_from(a * b);

  @:op(a *= b)
  static inline function mul_eq_scalar(a:Vector2, f:Float):Vector2
    return a.copy_from(a * f);

  @:op(a /= b)
  static inline function div_eq(a:Vector2, b:Vector2):Vector2
    return a.copy_from(a / b);

  @:op(a /= b)
  static inline function div_eq_scalar(a:Vector2, f:Float):Vector2
    return a.copy_from(a / f);

  @:op(a += b)
  static inline function add_eq(a:Vector2, b:Vector2):Vector2
    return a.copy_from(a + b);

  @:op(a += b)
  static inline function add_eq_scalar(a:Vector2, f:Float):Vector2
    return a.copy_from(a + f);

  @:op(a -= b)
  static inline function sub_eq(a:Vector2, b:Vector2):Vector2
    return a.copy_from(a - b);

  @:op(a -= b)
  static inline function sub_eq_scalar(a:Vector2, f:Float):Vector2
    return a.copy_from(a - f);

  // endregion
  // region getters

  static inline function get_zero():Vector2
    return new Vector2(0.0, 0.0);

  static inline function get_up():Vector2
    return new Vector2(0.0, 1.0);

  static inline function get_down():Vector2
    return new Vector2(0.0, -1.0);

  static inline function get_left():Vector2
    return new Vector2(-1.0, 0.0);

  static inline function get_right():Vector2
    return new Vector2(1.0, 0.0);

  inline function get_length():Float {
    var self:Vector2 = this;
    return Math.sqrt(self.dot(self));
  }

  inline function get_length_sq():Float {
    var self:Vector2 = this;
    return self.dot(self);
  }

  inline function get_radians():Float {
    var self = this;
    return Math.atan2(self.y, self.x);
  }

  inline function get_normal():Vector2 {
    var self:Vector2 = this;
    var len_sq = self.length_sq;
    var denominator = len_sq == 0.0 ? 1.0 : Math.sqrt(len_sq); // for 0 length, return zero vector rather than infinity (from vector-math lib)
    return self / denominator;
  }

  // endregion
  // region setters

  inline function set_length(f:Float):Float {
    var self:Vector2 = this;
    self.copy_from(normal * f);
    return f;
  }

  inline function set_radians(radians:Float):Float {
    var self:Vector2 = this;
    var len = length;
    self.set(len * Math.cos(radians), len * Math.sin(radians));
    return radians;
  }

  // endregion
}

inline function set(v:Vector2, x:Float, y:Float):Vector2 {
  v.x = x;
  v.y = y;
  return v;
}

inline function clone(v:Vector2):Vector2 {
  return new Vector2(v.x, v.y);
}

inline function copy_from(a:Vector2, b:Vector2):Vector2 {
  a.x = b.x;
  a.y = b.y;
  return a;
}

inline function copy_to(a:Vector2, b:Vector2):Vector2 {
  b.copy_from(a);
  return a;
}

inline function negate(v:Vector2)
  return v.set(-v.x, -v.y);

inline function distance(a:Vector2, b:Vector2):Float
  return (b - a).length;

inline function dot(a:Vector2, b:Vector2):Float
  return a.x * b.x + a.y * b.y;
/**
 * Normalizes a `Vector2` (in place).
 * @param v 
 * @return Vector2
 */
inline function normalize(v:Vector2):Vector2 {
  v.length = 1;
  return v;
}
/**
 * Rotates a `Vector2` (in place) by the specified amount of radians.
 * @param v The `Vector2` to modify.
 * @param radians The amount of radians to rotate.
 */
overload extern inline function rotate(v:Vector2, radians:Float):Vector2 {
  var cos = Math.cos(radians);
  var sin = Math.sin(radians);

  v.x = v.x * cos - v.y * sin;
  v.y = v.x * sin + v.y * cos;

  return v;
}
/**
 * Rotates a `Vector2` (in place) around a pivot by the specified amount of radians.
 * @param v The `Vector2` to modify.
 * @param radians The amount of radians to rotate.
 * @param pivot Pivot position to rotate the `Vector2` around.
 */
overload extern inline function rotate(v:Vector2, radians:Float, pivot:Vector2):Vector2 {
  var cos = Math.cos(radians);
  var sin = Math.sin(radians);
  var dx = v.x - pivot.x;
  var dy = v.y - pivot.y;

  v.x = dx * cos - dy * sin;
  v.y = dx * sin + dy * cos;

  return v;
}
/**
 * Rotates a `Vector2` (in place) by 90 degrees to the left/counterclockwise (-y, x).
 * @param v The `Vector2` to modify.
 */
inline function rotate_left(v:Vector2):Vector2 {
  var x = -v.y;
  v.y = v.x;
  v.x = x;

  return v;
}
/**
 * Rotates a `Vector2` (in place) by 90 degrees to the right/clockwise (y, -x). 
 * @param v The `Vector2` to modify.
 */
inline function rotate_right(v:Vector2):Vector2 {
  var x = v.y;
  v.y = -v.x;
  v.x = x;

  return v;
}

inline function lerp(a:Vector2, b:Vector2, t:Float):Vector2
  return new Vector2((1.0 - t) * a.x + t * b.x, (1.0 - t) * a.y + t * b.y);
/**
 * Normalizes a `Vector2` (in place) to represent the closest cardinal direction (Up, Down, Left, or Right).
 * @param v The `Vector2` to modify.
 * @return the modified `Vector2`
 */
inline function square_normal(v:Vector2):Vector2 {
  var len = v.length;
  var dot_x = v.dot(Vector2.right);
  var dot_y = v.dot(Vector2.up);
  if (dot_x.abs() > dot_y.abs()) dot_x > 0 ? v.set(1, 0) : v.set(-1, 0);
  else dot_y > 0 ? v.set(0, 1) : v.set(0, -1);
  v.length = len;
  return v;
}
/**
 * Gets the arc tangent angle between two `Vector2`, in radians.
 * @param v 
 * @param o 
 * @return Float
 */
overload extern inline function radians_between(v:Vector2, o:Vector2):Float
  return Math.atan2(v.x * o.y - v.y * o.x, v.x * o.x + v.y * o.y);
/**
 * Gets the arc tangent angle between three `Vector2`, in radians.
 * @param v 
 * @param left
 * @param right
 * @return Float
 */
overload extern inline function radians_between(v:Vector2, left:Vector2, right:Vector2):Float
  return radians_between(left - v, right - v);
