package echo;

import echo.util.AABB;
import hxmath.frames.Frame2;
import echo.util.Proxy;
import echo.shape.*;
import echo.data.Data;
import echo.data.Options;
import echo.data.Types;
import hxmath.math.Vector2;
/**
 * Base Shape Class. Acts as a Body's collider. Check out `echo.shapes` for all available shapes
 */
class Shape implements IProxy {
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
        s = Rect.get(options.offset_x, options.offset_y, options.width, options.height);
      case CIRCLE:
        s = Circle.get(options.offset_x, options.offset_y, options.radius);
      case POLYGON:
        if (options.vertices != null) s = Polygon.get_from_vertices(options.offset_x, options.offset_y, 0, options.vertices);
        else s = Polygon.get(options.offset_x, options.offset_y, options.sides, options.radius);
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
  public static inline function rect(?x:Float, ?y:Float, ?width:Float, ?height:Float) return Rect.get(x, y, width, height);
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
  public static inline function circle(?x:Float, ?y:Float, ?radius:Float) return Circle.get(x, y, radius);
  /**
   * Creates a new Shape
   * @param x
   * @param y
   */
  inline function new(x:Float = 0, y:Float = 0, rotation:Float = 0) {
    sync_pos = new Vector2(0, 0);
    solid = true;
    local_x = _x = x;
    local_y = _y = y;
    local_rotation = _rotation = rotation;
  }
  /**
   * Enum value determining what shape this Object is (Rect, Circle, Polygon).
   */
  public var type:ShapeType;
  /**
   * The Shape's position on the X axis.
   *
   * If added to a `Body`, this value is treated as an offset to the Body's X position.
   */
  public var x(get, set):Float;
  /**
   * The Shape's position on the Y axis.
   *
   * If added to a `Body`, this value is treated as an offset to the Body's Y position.
   */
  public var y(get, set):Float;

  public var rotation(get, set):Float;

  public var local_x(default, set):Float;

  public var local_y(default, set):Float;

  public var local_rotation(default, set):Float;
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

  var parent_frame:Frame2;
  /**
   * A cached `Vector2` used to reduce allocations. Used Internally.
   */
  var sync_pos:Vector2;

  var _x:Float;

  var _y:Float;

  var _rotation:Float;

  public function put() {
    parent_frame = null;
  }

  public function sync() {}
  /**
   * Gets the Shape's position on the X and Y axis as a `Vector2`.
   */
  public inline function get_position():Vector2 return new Vector2(_x, _y);

  public inline function get_local_position():Vector2 return new Vector2(local_x, local_y);

  public inline function set_local_position(value:Vector2):Vector2 {
    local_x = value.x;
    local_y = value.y;
    return value;
  }

  public function set_parent(?frame:Frame2) {
    parent_frame = frame;
    sync();
  }
  /**
   * Returns an AABB `Rect` representing the bounds of the `Shape`.
   * @param rect Optional `Rect` to set the values to.
   * @return Rect
   */
  public function bounds(?rect:AABB):AABB return rect == null ? AABB.get(x, y, 0, 0) : rect.set(x, y, 0, 0);
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

  function get_top():Float return y;

  function get_bottom():Float return y;

  function get_left():Float return x;

  function get_right():Float return x;

  // setters
  inline function set_x(value:Float):Float {
    if (parent_frame == null) return local_x = value;

    var pos = new Vector2(value, y);
    set_local_position(parent_frame.transformTo(pos));
    return _x;
  }

  inline function set_y(value:Float):Float {
    if (parent_frame == null) return local_y = value;

    var pos = new Vector2(x, value);
    set_local_position(parent_frame.transformTo(pos));
    return _y;
  }

  inline function set_rotation(value:Float):Float {
    if (parent_frame == null) return local_rotation = value;

    local_rotation = value - parent_frame.angleDegrees;
    return _rotation;
  }

  inline function set_local_x(value:Float):Float {
    local_x = value;

    if (parent_frame != null) sync();
    else _x = local_x;

    return local_x;
  }

  inline function set_local_y(value:Float):Float {
    local_y = value;

    if (parent_frame != null) sync();
    else _y = local_y;

    return local_y;
  }

  inline function set_local_rotation(value:Float):Float {
    local_rotation = value;

    if (parent_frame != null) sync();
    else _rotation = local_rotation;

    return local_rotation;
  }

  static function get_defaults():ShapeOptions return {
    type: RECT,
    radius: 1,
    width: 1,
    height: 0,
    sides: 3,
    rotation: 0,
    offset_x: 0,
    offset_y: 0,
    solid: true
  }
}
