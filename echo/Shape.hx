package echo;

import glib.Proxy;
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
    options = glib.Data.copy_fields(options, defaults);
    switch (options.type) {
      case RECT:
        return Rect.get(options.offset_x, options.offset_y, options.width, options.height);
      case CIRCLE:
        return Circle.get(options.offset_x, options.offset_y, options.radius);
      case POLYGON:
        throw 'Polygon Shape has not been implemented';
    }
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
   * @return position = new Vector2(x, y)
   */
  function new(x:Float = 0, y:Float = 0) position = new Vector2(x, y);
  /**
   * The Shape's position on the X axis.
   *
   * If added to a `Body`, this value is treated as an offset to the Body's X position.
   *
   * Alias for `position.x`.
   */
  @:alias(position.x)
  public var x:Float;
  /**
   * The Shape's position on the Y axis.
   *
   * If added to a `Body`, this value is treated as an offset to the Body's Y position.
   *
   * Alias for `position.y`.
   */
  @:alias(position.y)
  public var y:Float;
  /**
   * Enum value determining what shape this Object is (Rect, Circle, Polygon).
   */
  public var type:ShapeType;
  /**
   * Shape's position on the X and Y axis.
   *
   * If added to a `Body`, this value is treated as an offset to the Body's position.
   */
  public var position:Vector2;
  /**
   * The Upper Bounds of the Shape.
   */
  @:alias(position.y)
  public var top(get, null):Float;
  /**
   * The Lower Bounds of the Shape.
   */
  @:alias(position.y)
  public var bottom(get, null):Float;
  /**
   * The Left Bounds of the Shape.
   */
  @:alias(position.x)
  public var left(get, null):Float;
  /**
   * The Right Bounds of the Shape.
   */
  @:alias(position.x)
  public var right(get, null):Float;

  public function put() {}
  /**
   * Returns an AABB `Rect` representing the bounds of the `Shape`.
   * @param rect Optional `Rect` to set to the value bounds of the Shape's bounds.
   * @return Rect
   */
  public function bounds(?rect:Rect) return rect == null ? Rect.get(x, y, 0, 0) : rect.set(x, y, 0, 0);
  /**
   * Clones the Shape into a new Shape
   * @return Shape return new Shape(x, y)
   */
  public function clone():Shape return new Shape(x, y);

  public function scale(v:Float) {}

  public function contains(v:Vector2):Bool return position == v;

  public function intersects(l:Line):Null<IntersectionData> return null;

  public function overlaps(s:Shape):Bool return contains(s.position);

  public function collides(s:Shape):Null<CollisionData> return null;

  function collide_rect(r:Rect):Null<CollisionData> return null;

  function collide_circle(c:Circle):Null<CollisionData> return null;

  static function get_defaults():ShapeOptions return {
    type: RECT,
    radius: 8,
    width: 16,
    height: 16,
    points: [],
    rotation: 0,
    offset_x: 0,
    offset_y: 0
  }
}
