package echo.util;

import echo.util.Disposable;
import hxmath.math.Matrix3x3;
import hxmath.math.Vector2;
import hxmath.math.Vector3;

using Math;
using echo.util.ext.FloatExt;

class Transform implements IDisposable #if cog implements cog.IComponent #end {
  /**
   * The Transform's position on the X axis in world coordinates.
   */
  public var x(get, set):Float;
  /**
   * The Transform's position on the Y axis in world coordinates.
   */
  public var y(get, set):Float;
  /**
   * The Transform's rotation (as degrees) in world coordinates.
   */
  public var rotation(get, set):Float;
  /**
   * The Transform's scale on the X axis in world coordinates.
   */
  public var scale_x(get, set):Float;
  /**
   * The Transform's scale on the Y axis in world coordinates.
   */
  public var scale_y(get, set):Float;
  /**
   * The Transform's position on the X axis in local coordinates.
   */
  public var local_x(default, set):Float;
  /**
   * The Transform's position on the Y axis in local coordinates.
   */
  public var local_y(default, set):Float;
  /**
   * The Transform's rotation (as degrees) in local coordinates.
   */
  public var local_rotation(default, set):Float;
  /**
   * The Transform's scale on the X axis in local coordinates.
   */
  public var local_scale_x(default, set):Float;
  /**
   * The Transform's scale on the Y axis in local coordinates.
   */
  public var local_scale_y(default, set):Float;

  public var right(get, never):Vector2;
  public var left(get, never):Vector2;
  public var up(get, never):Vector2;
  public var down(get, never):Vector2;
  /**
   * Optional callback method that gets called when the Transform is set as dirty.
   */
  public var on_dirty:Transform->Void = null;

  var _x:Float = 0;
  var _y:Float = 0;
  var _rotation:Float = 0;
  var _scale_x:Float = 1;
  var _scale_y:Float = 1;

  var parent:Null<Transform>;
  var children:Array<Transform> = [];
  var local_to_world_matrix = Matrix3x3.identity;
  var world_to_local_matrix = Matrix3x3.identity;
  var dirty = false;
  var inverse_dirty = false;
  var coordinates_dirty:Bool = false;
  /**
   * Gets the translated `Matrix3x3 representing the defined `x` and `y`.
   */
  public static inline function translate(x:Float, y:Float):Matrix3x3 {
    return new Matrix3x3(1, 0, x, 0, 1, y, 0, 0, 1);
  }
  /**
   * Gets the rotated `Matrix3x3` representing the defined `radians`.
   */
  public static inline function rotate(radians:Float):Matrix3x3 {
    var s = Math.sin(radians);
    var c = Math.cos(radians);
    return new Matrix3x3(c, -s, 0, s, c, 0, 0, 0, 1);
  }
  /**
   * Gets the scaled `Matrix3x3` representing the defined `scale_x` and `scale_y`.
   */
  public static inline function scale(scale_x:Float, scale_y:Float):Matrix3x3 {
    return new Matrix3x3(scale_x, 0, 0, 0, scale_y, 0, 0, 0, 1);
  }
  /**
   * Multiplies the `Vector3` by a transposed form of the `Matrix3x3`.
   *
   * Transposed form:
   * ```
   * vec3.x = m00 * x, m01 * y, m02 * z
   * vec3.y = m10 * x, m11 * y, m12 * z
   * vec3.z = m20 * x, m21 * y, m22 * z
   * ```
   * @param v
   * @param a
   * @return Vector3
   */
  @:op(A * B)
  public static inline function multiply_transposed_matrix(v:Vector3, a:Matrix3x3):Vector3 {
    return new Vector3(a.m00 * v.x
      + a.m01 * v.y
      + a.m02 * v.z, a.m10 * v.x
      + a.m11 * v.y
      + a.m12 * v.z, a.m20 * v.x
      + a.m21 * v.y
      + a.m22 * v.z);
  }

  public function new(x:Float = 0, y:Float = 0, rotation:Float = 0, scale_x:Float = 1, scale_y:Float = 1) {
    local_x = x;
    local_y = y;
    local_rotation = rotation;
    local_scale_x = scale_x;
    local_scale_y = scale_y;
  }
  /**
   * Gets this Transform's parent Transform, if it has one.
  **/
  public inline function get_parent() {
    return parent;
  }
  /**
   * Sets this Transform's parent.
   *
   * TODO - implement `preserve_world_transform` arguement.
   *
   * @param parent
   * @param preserve_world_transform
   */
  public function set_parent(parent:Null<Transform>, preserve_world_transform:Bool = false) {
    // remove this from the previous parent
    if (this.parent != null) {
      this.parent.children.remove(this);
    }
    // assign new parent
    this.parent = parent;

    // add this to new parent
    if (parent != null) {
      this.parent.children.push(this);
    }

    set_dirty(true);
  }
  /**
   * Gets the Matrix representing the local coordinates' transformation.
   * @return Matrix3x3
   */
  public inline function get_local_matrix():Matrix3x3 {
    // translate(local_x, local_y) * rotate(local_rotation.deg_to_rad()) * scale(local_scale_x, local_scale_y);
    var radians = local_rotation.deg_to_rad();
    var s = Math.sin(radians);
    var c = Math.cos(radians);
    return new Matrix3x3(c * local_scale_x, -s * local_scale_y, local_x, s * local_scale_x, c * local_scale_y, local_y, 0, 0, 1);
  }
  /**
   * Gets the Matrix that converts from local coordinates to world coordinates.
   * @return Matrix3x3
   */
  public function get_local_to_world_matrix():Matrix3x3 {
    if (dirty) {
      if (parent == null) get_local_matrix().copyTo(local_to_world_matrix);
      else (parent.get_local_to_world_matrix() * get_local_matrix()).copyTo(local_to_world_matrix);
      dirty = false;
    }
    return local_to_world_matrix;
  }
  /**
   * Gets the Inversed Matrix based on the `local_to_world_matrix`.
   */
  public function get_world_to_local_matrix():Matrix3x3 {
    if (inverse_dirty) {
      var m = get_local_to_world_matrix();
      var a = m.m00;
      var b = m.m01;
      var c = m.m10;
      var d = m.m11;
      var tx = m.m20;
      var ty = m.m21;

      var norm = a * d - b * c;

      if (norm == 0) {
        a = b = c = d = 0;
        tx = -tx;
        ty = -ty;
      }
      else {
        norm = 1.0 / norm;
        var a1 = d * norm;
        d = a * norm;
        a = a1;
        b *= -norm;
        c *= -norm;

        var tx1 = -a * tx - c * ty;
        ty = -b * tx - d * ty;
        tx = tx1;
      }

      world_to_local_matrix.m00 = a;
      world_to_local_matrix.m01 = b;
      world_to_local_matrix.m10 = c;
      world_to_local_matrix.m11 = d;
      world_to_local_matrix.m20 = tx;
      world_to_local_matrix.m21 = ty;

      inverse_dirty = false;
    }
    return world_to_local_matrix;
  }
  /**
   * Transforms a point from local coordinates to world coordinates.
   * @param x
   * @param y
   * @return Vector2
   */
  public inline function point_to_world(x:Float = 0, y:Float = 0):Vector2 {
    var result = get_local_to_world_matrix() * new Vector3(x, y, 1);
    return new Vector2(result.x, result.y);
  }
  /**
   * Transforms a point from world coordinates to local coordinates.
   * @param x
   * @param y
   * @return Vector2
   */
  public inline function point_to_local(x:Float = 0, y:Float = 0):Vector2 {
    var result = get_world_to_local_matrix() * new Vector3(x, y, 1);
    return new Vector2(result.x, result.y);
  }
  /**
   * Transforms a direction vector from local coordinates to world coordinates.
   * @param x
   * @param y
   * @return Vector2
   */
  public inline function direction_to_world(x:Float = 1, y:Float = 0):Vector2 {
    var result = multiply_transposed_matrix(new Vector3(x, y, 0), get_world_to_local_matrix());
    return new Vector2(result.x, result.y);
  }
  /**
   * Transforms a direction vector from world coordinates to local coordinates.
   * @param x
   * @param y
   * @return Vector2
   */
  public inline function direction_to_local(x:Float = 1, y:Float = 0):Vector2 {
    var result = multiply_transposed_matrix(new Vector3(x, y, 0), get_local_to_world_matrix());
    return new Vector2(result.x, result.y);
  }
  /**
   * Transforms an angle (in degrees) from local rotation to world rotation.
   * @param degrees
   * @return Float
   */
  public inline function rotation_to_world(degrees:Float = 0):Float {
    var radians = degrees.deg_to_rad();
    var result = multiply_transposed_matrix(new Vector3(Math.cos(radians), Math.sin(radians), 0), get_world_to_local_matrix());
    return Math.atan2(result.y, result.x).rad_to_deg();
  }
  /**
   * Transforms an angle (in degrees) from world rotation to local rotation.
   * @param degrees
   * @return Float
   */
  public inline function rotation_to_local(degrees:Float = 0):Float {
    var radians = degrees.deg_to_rad();
    var result = multiply_transposed_matrix(new Vector3(Math.cos(radians), Math.sin(radians), 0), get_local_to_world_matrix());
    return Math.atan2(result.y, result.x).rad_to_deg();
  }
  /**
   * Transforms a scale vector from local coordinates to world coordinates.
   * @param scale_x
   * @param scale_y
   * @return Vector2
   */
  public inline function scale_to_world(scale_x:Float = 0, scale_y:Float = 0):Vector2 {
    var m = get_local_to_world_matrix();
    return new Vector2(Math.sqrt(m.m00 * m.m00 + m.m01 * m.m01) * scale_x, Math.sqrt(m.m10 * m.m10 + m.m11 * m.m11) * scale_y);
  }
  /**
   * Transforms a scale vector from world coordinates to local coordinates.
   * @param scale_x
   * @param scale_y
   * @return Vector2
   */
  public inline function scale_to_local(scale_x:Float = 0, scale_y:Float = 0):Vector2 {
    var m = get_world_to_local_matrix();
    return new Vector2(Math.sqrt(m.m00 * m.m00 + m.m01 * m.m01) * scale_x, Math.sqrt(m.m10 * m.m10 + m.m11 * m.m11) * scale_y);
  }
  /**
   * Gets the Transform's position in world coordinates.
   */
  public inline function get_position() {
    sync();
    return new Vector2(_x, _y);
  }
  /**
   * Sets the Transform's position from world coordinates.
   * @param position
   */
  public inline function set_position(position:Vector2) {
    if (parent == null) set_local_position(position);
    else set_local_position(parent.point_to_local(position.x, position.y));
  }

  public inline function set_xy(x:Float = 0, y:Float = 0) {
    this.x = x;
    this.y = y;
  }
  /**
   * Gets the Transform's scale in world coordinates.
   */
  public inline function get_scale() {
    sync();
    return new Vector2(_scale_x, _scale_y);
  }
  /**
   * Sets the Transform's scale from world coordinates.
   * @param scale
   */
  public inline function set_scale(scale:Vector2) {
    if (parent == null) set_local_scale(scale);
    else set_local_scale(parent.scale_to_local(scale.x, scale.y));
  }

  public inline function set_scale_xy(x:Float = 0, y:Float = 0) {
    scale_x = x;
    scale_y = y;
  }
  /**
   * Gets the Transform's position in local coordinates.
   */
  public inline function get_local_position() {
    return new Vector2(local_x, local_y);
  }
  /**
   * Sets the Transform's position from local coordinates.
   * @param position
   */
  public inline function set_local_position(position:Vector2) {
    local_x = position.x;
    local_y = position.y;
  }

  public inline function set_local_xy(x:Float = 0, y:Float = 0) {
    local_x = x;
    local_y = y;
  }
  /**
   * Gets the Transform's scale in local coordinates.
   */
  public inline function get_local_scale() {
    return new Vector2(local_scale_x, local_scale_y);
  }

  public inline function set_local_scale_xy(x:Float = 0, y:Float = 0) {
    local_scale_x = x;
    local_scale_y = y;
  }
  /**
   * Sets the Transform's scale from local coordinates.
   * @param scale
   */
  public function set_local_scale(scale:Vector2) {
    local_scale_x = scale.x;
    local_scale_y = scale.y;
  }
  /**
   * Disposes the Transform. DO NOT use the Transform after disposing it, as it could lead to null reference errors.
   */
  public function dispose() {
    on_dirty = null;
    for (child in children) child.set_parent(null, true);
    children = null;
    parent = null;
    local_to_world_matrix = null;
    world_to_local_matrix = null;
  }
  /** 
   * If the Transform is dirty, the Transform's world coordinates are updated.
  **/
  function sync() {
    if (!coordinates_dirty) return;

    // ensure the matrix is up to date, even if there is no parent
    var m = get_local_to_world_matrix();

    if (parent == null) {
      _x = local_x;
      _y = local_y;
      _scale_x = local_scale_x;
      _scale_y = local_scale_y;
      _rotation = local_rotation;
    }
    else {
      var a = m.m00;
      var b = m.m01;
      var c = m.m10;
      var d = m.m11;
      _x = m.m20;
      _y = m.m21;
      _scale_x = Math.sqrt(a * a + b * b);
      _scale_y = Math.sqrt(c * c + d * d);
      _rotation = Math.atan2(-c / _scale_y, a / _scale_x).rad_to_deg();
    }

    coordinates_dirty = false;
  }

  inline function set_dirty(force:Bool = false) {
    if (force || !dirty) {
      dirty = inverse_dirty = coordinates_dirty = true;
      for (child in children) {
        child.set_dirty(true);
      }
      if (on_dirty != null) on_dirty(this);
    }
  }

  inline function get_x() {
    if (parent == null) return local_x;
    sync();
    return _x;
  }

  inline function get_y() {
    if (parent == null) return local_y;
    sync();
    return _y;
  }

  inline function get_rotation() {
    if (parent == null) return local_rotation;
    sync();
    return _rotation;
  }

  inline function get_scale_x() {
    if (parent == null) return local_scale_x;
    sync();
    return _scale_x;
  }

  inline function get_scale_y() {
    if (parent == null) return local_scale_y;
    sync();
    return _scale_y;
  }

  inline function get_right() {
    return Vector2.fromPolar(rotation.deg_to_rad(), 1);
  }

  inline function get_left() {
    return Vector2.fromPolar((rotation + 180).deg_to_rad(), 1);
  }

  inline function get_up() {
    return Vector2.fromPolar((rotation + 90).deg_to_rad(), 1);
  }

  inline function get_down() {
    return Vector2.fromPolar((rotation - 90).deg_to_rad(), 1);
  }

  inline function set_x(v:Float) {
    if (parent == null) return local_x = v;
    set_local_position(parent.point_to_local(v, y));
    return x;
  }

  inline function set_y(v:Float) {
    if (parent == null) return local_y = v;
    set_local_position(parent.point_to_local(x, v));
    return y;
  }

  inline function set_rotation(v:Float) {
    if (parent == null) return local_rotation = v;
    local_rotation = parent.rotation_to_local(v);
    return rotation;
  }

  inline function set_scale_x(v:Float) {
    if (parent == null) return local_scale_x = v;
    set_local_scale(parent.scale_to_local(v, scale_y));
    return scale_x;
  }

  inline function set_scale_y(v:Float) {
    if (parent == null) return local_scale_y = v;
    set_local_scale(parent.scale_to_local(scale_x, v));
    return scale_y;
  }

  inline function set_local_x(v:Float) {
    set_dirty();
    return local_x = v;
  }

  inline function set_local_y(v:Float) {
    set_dirty();
    return local_y = v;
  }

  inline function set_local_rotation(v:Float) {
    set_dirty();
    return local_rotation = v;
  }

  inline function set_local_scale_x(v:Float) {
    set_dirty();
    return local_scale_x = v;
  }

  inline function set_local_scale_y(v:Float) {
    set_dirty();
    return local_scale_y = v;
  }
}
