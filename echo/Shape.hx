package echo;

import echo.shape.*;
import hxmath.math.Vector2;

using echo.Collisions;

class Shape {
  /**
   * Default Shape Options
   */
  public static var defaults(get, null):ShapeOptions;

  public var x(get, set):Float;
  public var y(get, set):Float;
  public var type:ShapeType;
  public var position:Vector2;
  public var top(get, null):Float;
  public var bottom(get, null):Float;
  public var left(get, null):Float;
  public var right(get, null):Float;

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

  public static inline function rect(?x:Float, ?y:Float, ?width:Float, ?height:Float) return Rect.get(x, y, width, height);

  public static inline function square(?x:Float, ?y:Float, ?width:Float) return Rect.get(x, y, width, width);

  public static inline function circle(?x:Float, ?y:Float, ?radius:Float) return Circle.get(x, y, radius);

  function new(x:Float = 0, y:Float = 0) position = new Vector2(x, y);

  public function put() {}

  public function to_aabb(?rect:Rect) return rect == null ? Rect.get(x, y, 0, 0) : rect.set(x, y, 0, 0);

  public function clone():Shape return new Shape(x, y);

  public function scale(v:Float) {}

  public function contains(v:Vector2):Bool return position == v;

  public function intersects(l:Line):Null<IntersectionData> return null;

  public function overlaps(s:Shape):Bool return contains(s.position);

  public function collides(s:Shape):Null<CollisionData> return null;

  function collide_rect(r:Rect):Null<CollisionData> return null;

  function collide_circle(c:Circle):Null<CollisionData> return null;

  // getters
  function get_x():Float return position.x;

  function get_y():Float return position.y;

  function get_top():Float return position.y;

  function get_bottom():Float return position.y;

  function get_left():Float return position.x;

  function get_right():Float return position.x;

  // setters
  function set_x(value:Float):Float return position.x = value;

  function set_y(value:Float):Float return position.y = value;

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

typedef ShapeOptions = {
  var ?type:ShapeType;
  var ?radius:Float;
  var ?width:Float;
  var ?height:Float;
  var ?points:Array<Vector2>;
  var ?rotation:Float;
  var ?offset_x:Float;
  var ?offset_y:Float;
}

@:enum
abstract ShapeType(Int) from Int to Int {
  var RECT = 0;
  var CIRCLE = 1;
  var POLYGON = 2;
}
