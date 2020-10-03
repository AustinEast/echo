package echo;

import echo.util.AABB;
import hxmath.frames.Frame2;
import echo.shape.*;
import echo.data.Data;
import echo.data.Options;
import echo.data.Types;
import hxmath.math.Vector2;
/**
 * Base Shape Class. Acts as a Body's collider. Check out `echo.shapes` for all available shapes
 */
class Shape {
  /**
   * Default Shape Options
   */
  public static var defaults(get, null):ShapeOptions;
  /**
   * Gets a Shape. If one is available, it will be grabbed from the Object Pool. Otherwise a new Shape will be created.
   * @param options
   * @return Shape
   */
  public static function get(options:ShapeOptions):Shape {
    options = echo.util.JSON.copy_fields(options, defaults);
    var s:Shape;
    switch (options.type) {
      case RECT:
        s = Rect.get(options.offset_x, options.offset_y, options.width, options.height, options.rotation, options.scale_x, options.scale_y);
      case CIRCLE:
        s = Circle.get(options.offset_x, options.offset_y, options.radius, options.rotation, options.scale_x, options.scale_y);
      case POLYGON:
        if (options.vertices != null) s = Polygon.get_from_vertices(options.offset_x, options.offset_y, options.rotation, options.vertices, options.scale_x,
          options.scale_y);
        else s = Polygon.get(options.offset_x, options.offset_y, options.sides, options.radius, options.rotation, options.scale_x, options.scale_y);
    }
    s.solid = options.solid;
    return s;
  }
  /**
   * Gets a `Rect` from the Rect Classes' Object Pool. Shortcut for `Rect.get()`.
   * @param x The X position of the Rect
   * @param y The Y position of the Rect
   * @param width The width of the Rect
   * @param height The height of the Rect
   * @return Rect
   */
  public static inline function rect(?x:Float, ?y:Float, ?width:Float, ?height:Float, ?scale_x:Float,
      ?scale_y:Float) return Rect.get(x, y, width, height, scale_x, scale_y);
  /**
   * Gets a `Rect` with uniform width/height from the Rect Classes' Object Pool. Shortcut for `Rect.get()`.
   * @param x The X position of the Rect
   * @param y The Y position of the Rect
   * @param width The width of the Rect
   * @return Rect
   */
  public static inline function square(?x:Float, ?y:Float, ?width:Float) return Rect.get(x, y, width, width);
  /**
   * Gets a `Circle` from the Circle Classes' Object Pool. Shortcut for `Circle.get()`.
   * @param x The X position of the Circle
   * @param y The Y position of the Circle
   * @param radius The radius of the Circle
   * @return Rect
   */
  public static inline function circle(?x:Float, ?y:Float, ?radius:Float, ?scale_x:Float, ?scale_y:Float) return Circle.get(x, y, radius, scale_x, scale_y);
  /**
   * Creates a new Shape
   * @param x
   * @param y
   */
  inline function new(x:Float = 0, y:Float = 0, rotation:Float = 0) {
    sync_pos = new Vector2(0, 0);
    solid = true;
    sync_locked = false;
    local_x = _x = x;
    local_y = _y = y;
    local_rotation = _rotation = rotation;
  }
  /**
   * Enum value determining what shape this Object is (Rect, Circle, Polygon).
   */
  public var type:ShapeType;
  /**
   * The Shape's position on the X axis. For Rects, Circles, and simple Polygons, this position is based on the center of the Shape.
   *
   * If added to a `Body`, this value is relative to the Body's X position. To get the Shape's local X position in this case, use `local_x`.
   */
  public var x(get, set):Float;
  /**
   * The Shape's position on the Y axis. For Rects, Circles, and simple Polygons, this position is based on the center of the Shape.
   *
   * If added to a `Body`, this value is relative to the Body's Y position. To get the Shape's local Y position in this case, use `local_y`.
   */
  public var y(get, set):Float;
  /**
   * The Shape's angular rotation.
   *
   * If added to a `Body`, this value is relative to the Body's rotation. To get the Shape's local rotation in this case, use `local_rotation`.
   */
  public var rotation(get, set):Float;

  public var scale_x(get, set):Float;

  public var scale_y(get, set):Float;
  /**
   * The Shape's position on the X axis. For Rects, Circles, and simple Polygons, this position is based on the center of the Shape.
   *
   * If added to a `Body`, this value is treated as an offset to the Body's X position.
   */
  public var local_x(default, set):Float;
  /**
   * The Shape's position on the Y axis. For Rects, Circles, and simple Polygons, this position is based on the center of the Shape.
   *
   * If added to a `Body`, this value is treated as an offset to the Body's Y position.
   */
  public var local_y(default, set):Float;

  public var local_rotation(default, set):Float;

  public var local_scale_x(default, set):Float;

  public var local_scale_y(default, set):Float;
  /**
   * Flag to set whether the Shape collides with other Shapes.
   *
   * If false, this Shape's Body will not have its position or velocity affected by other Bodies, but it will still call collision callbacks
   */
  public var solid:Bool;
  /**
   * The Upper Bounds of the Shape.
   */
  public var top(get, never):Float;
  /**
   * The Lower Bounds of the Shape.
   */
  public var bottom(get, never):Float;
  /**
   * The Left Bounds of the Shape.
   */
  public var left(get, never):Float;
  /**
   * The Right Bounds of the Shape.
   */
  public var right(get, never):Float;
  /**
   * Flag to determine if the Shape has collided in the last `World` step. Used Internally for Debugging.
   */
  public var collided:Bool;

  public var sync_locked(default, null):Bool;

  var parent(default, null):Body;
  /**
   * A cached `Vector2` used to reduce allocations. Used Internally.
   */
  var sync_pos:Vector2;

  var _x:Float;
  var _y:Float;
  var _rotation:Float;
  var _scale_x:Float;
  var _scale_y:Float;

  public function put() {
    parent = null;
  }

  public inline function sync():Void {
    if (parent != null) {
      if (local_x == 0 && local_y == 0) {
        _x = parent.frame.offset.x;
        _y = parent.frame.offset.y;
      }
      else {
        sync_pos.set(local_x * parent.scale_x, local_y * parent.scale_y);
        var pos = parent.frame.transformFrom(sync_pos);
        _x = pos.x;
        _y = pos.y;
      }
      _rotation = parent.frame.angleDegrees + local_rotation;
      _scale_x = parent.scale_x * local_scale_x;
      _scale_y = parent.scale_y * local_scale_y;
    }
    else {
      _x = local_x;
      _y = local_x;
      _rotation = local_rotation;
    }
    transform();
  }
  /**
   * Gets the Shape's position on the X and Y axis as a `Vector2`.
   */
  public inline function get_position():Vector2 return new Vector2(_x, _y);

  public inline function get_local_position():Vector2 return new Vector2(local_x, local_y);

  public inline function set_position(value:Vector2):Void {
    x = value.x;
    y = value.y;
  }

  public inline function set_local_position(value:Vector2):Void {
    local_x = value.x;
    local_y = value.y;
  }

  public function set_parent(?body:Body):Void {
    if (parent == body) return;
    parent = body;
    sync();
  }

  public function lock_sync() {
    sync_locked = true;
  }

  public function unlock_sync() {
    sync_locked = false;
    sync();
  }
  /**
   * Returns an `AABB` representing the bounds of the `Shape`.
   * @param aabb Optional `AABB` to set the values to.
   * @return AABB
   */
  public function bounds(?aabb:AABB):AABB return aabb == null ? AABB.get(x, y, 0, 0) : aabb.set(x, y, 0, 0);
  /**
   * Clones the Shape into a new Shape
   * @return Shape return new Shape(x, y)
   */
  public function clone():Shape return new Shape(x, y, rotation);

  // public function scale(v:Float) {}
  public function contains(v:Vector2):Bool return get_position() == v;

  public function intersect(l:Line):Null<IntersectionData> return null;

  public function overlaps(s:Shape):Bool return contains(s.get_position());

  public function collides(s:Shape):Null<CollisionData> return null;

  function collide_rect(r:Rect):Null<CollisionData> return null;

  function collide_circle(c:Circle):Null<CollisionData> return null;

  function collide_polygon(p:Polygon):Null<CollisionData> return null;

  function transform() {}

  function toString() {
    var s = switch (type) {
      case RECT: 'rect';
      case CIRCLE: 'circle';
      case POLYGON: 'polygon';
    }
    return 'Shape: {type: $s, x: $x, y: $y, rotation: $rotation}';
  }

  // getters
  inline function get_x():Float return _x;

  inline function get_y():Float return _y;

  inline function get_rotation():Float return _rotation;

  inline function get_scale_x():Float return _scale_x;

  inline function get_scale_y():Float return _scale_y;

  function get_top():Float return y;

  function get_bottom():Float return y;

  function get_left():Float return x;

  function get_right():Float return x;

  // setters
  inline function set_x(value:Float):Float {
    if (parent == null) return local_x = value;

    var pos = new Vector2(value, y);
    set_local_position(parent.frame.transformTo(pos));
    return _x;
  }

  inline function set_y(value:Float):Float {
    if (parent == null) return local_y = value;

    var pos = new Vector2(x, value);
    set_local_position(parent.frame.transformTo(pos));
    return _y;
  }

  inline function set_rotation(value:Float):Float {
    if (parent == null) return local_rotation = value;

    local_rotation = value - parent.frame.angleDegrees;
    return _rotation;
  }

  inline function set_scale_x(value:Float):Float {
    if (parent == null) return local_scale_x = value;
    local_scale_x = value / parent.scale_x;
    return _scale_x;
  }

  inline function set_scale_y(value:Float):Float {
    if (parent == null) return local_scale_y = value;
    local_scale_y = value / parent.scale_y;
    return _scale_y;
  }

  inline function set_local_x(value:Float):Float {
    local_x = value;

    if (parent != null) {
      if (!sync_locked) sync();
    }
    else _x = local_x;

    return local_x;
  }

  inline function set_local_y(value:Float):Float {
    local_y = value;

    if (parent != null) {
      if (!sync_locked) sync();
    }
    else _y = local_y;

    return local_y;
  }

  inline function set_local_rotation(value:Float):Float {
    local_rotation = value;

    if (parent != null) {
      if (!sync_locked) sync();
    }
    else _rotation = local_rotation;

    return local_rotation;
  }

  inline function set_local_scale_x(value:Float):Float {
    local_scale_x = value;

    if (parent != null) {
      if (!sync_locked) sync();
    }
    else _scale_x = local_scale_x;

    return local_scale_x;
  }

  inline function set_local_scale_y(value:Float):Float {
    local_scale_y = value;

    if (parent != null) {
      if (!sync_locked) sync();
    }
    else _scale_y = local_scale_y;

    return local_scale_y;
  }

  static function get_defaults():ShapeOptions return {
    type: RECT,
    radius: 1,
    width: 1,
    height: 0,
    sides: 3,
    rotation: 0,
    scale_x: 1,
    scale_y: 1,
    offset_x: 0,
    offset_y: 0,
    solid: true
  }
}
