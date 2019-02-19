package echo;

import hxmath.math.Vector2;
import glib.Disposable;
import echo.Shape;
import echo.Echo;
import echo.shape.Rect;

class Body implements IEcho implements IDisposable {
  /**
   * Default Body Options
   */
  public static var defaults(get, null):BodyOptions;
  static var ids:Int = 0;

  public var id(default, null):Int;
  @:isVar
  public var shape(get, set):Null<Shape>;
  @:isVar
  public var solid(get, set):Bool;
  @:isVar
  public var mass(get, set):Float;
  public var x(get, set):Float;
  public var y(get, set):Float;
  @:isVar
  public var position(get, set):Vector2;
  @:isVar
  public var rotation(get, set):Float;
  @:isVar
  public var elasticity(get, set):Float;
  @:isVar
  public var velocity(get, set):Vector2;
  @:isVar
  public var acceleration(get, set):Vector2;
  @:isVar
  public var rotational_velocity(get, set):Float;
  @:isVar
  public var max_velocity(get, set):Vector2;
  @:isVar
  public var max_rotational_velocity(get, set):Float;
  @:isVar
  public var drag(get, set):Vector2;
  public var inverse_mass(default, null):Float;
  public var active:Bool;
  public var type(default, null):EchoType;
  /**
   * Flag to check if the body collided with something during the step.
   * Used for debug drawing.
   */
  public var collided:Bool;

  public function new(?options:BodyOptions) {
    this.id = ++ids;
    active = true;
    type = BODY;
    position = new Vector2(0, 0);
    velocity = new Vector2(0, 0);
    acceleration = new Vector2(0, 0);
    max_velocity = new Vector2(0, 0);
    drag = new Vector2(0, 0);
    load(options);
  }

  public function load(?options:BodyOptions) {
    options = glib.Data.copy_fields(options, defaults);
    if (options.shape != null) shape = Shape.get(options.shape);
    solid = options.solid;
    mass = options.mass;
    position.set(options.x, options.y);
    elasticity = options.elasticity;
    velocity.set(options.velocity_x, options.velocity_y);
    rotational_velocity = options.rotational_velocity;
    max_velocity.set(options.max_velocity_x, options.max_velocity_y);
    max_rotational_velocity = options.max_rotational_velocity;
    drag.set(options.drag_x, options.drag_y);
  }

  public function push(x:Float = 0, y:Float = 0) {
    acceleration.x += x;
    acceleration.y += y;
  }

  public function bounds():Null<Rect> {
    if (shape == null) return null;
    var b = shape.to_aabb();
    b.position.addWith(position);
    return b;
  }

  public function dispose() {
    shape.put();
    velocity = null;
    max_velocity = null;
    drag = null;
  }

  // getters
  function get_shape():Null<Shape> return shape;

  function get_mass():Float return mass;

  function get_solid():Bool return solid;

  function get_x():Float return position.x;

  function get_y():Float return position.y;

  function get_position():Vector2 return position;

  function get_rotation():Float return rotation;

  function get_elasticity():Float return elasticity;

  function get_velocity():Vector2 return velocity;

  function get_acceleration():Vector2 return acceleration;

  function get_rotational_velocity():Float return rotational_velocity;

  function get_max_velocity():Vector2 return max_velocity;

  function get_max_rotational_velocity():Float return max_rotational_velocity;

  function get_drag():Vector2 return drag;

  // setters
  function set_shape(value:Null<Shape>):Null<Shape> return shape = value;

  function set_mass(value:Float):Float {
    if (value < 0.0001) {
      value = 0;
      inverse_mass = 0;
    }
    else inverse_mass = 1 / value;
    return mass = value;
  }

  function set_solid(value:Bool):Bool return solid = value;

  function set_x(value:Float) return position.x = value;

  function set_y(value:Float) return position.y = value;

  function set_position(value:Vector2) return position = value;

  function set_rotation(value:Float) return rotation = value;

  function set_elasticity(value:Float) return elasticity = value;

  function set_velocity(value:Vector2) return velocity = value;

  function set_acceleration(value:Vector2) return acceleration = value;

  function set_rotational_velocity(value:Float) return rotational_velocity = value;

  function set_max_velocity(value:Vector2) return max_velocity = value;

  function set_max_rotational_velocity(value:Float) return max_rotational_velocity = value;

  function set_drag(value:Vector2) return drag = value;

  static function get_defaults():BodyOptions return {
    solid: true,
    mass: 1,
    x: 0,
    y: 0,
    elasticity: 0,
    velocity_x: 0,
    velocity_y: 0,
    rotational_velocity: 0,
    max_velocity_x: 0,
    max_velocity_y: 0,
    max_rotational_velocity: 10000,
    drag_x: 0,
    drag_y: 0
  }
}

typedef BodyOptions = {
  var ?shape:ShapeOptions;
  var ?solid:Bool;
  var ?mass:Float;
  var ?x:Float;
  var ?y:Float;
  var ?elasticity:Float;
  var ?velocity_x:Float;
  var ?velocity_y:Float;
  var ?rotational_velocity:Float;
  var ?max_velocity_x:Float;
  var ?max_velocity_y:Float;
  var ?max_rotational_velocity:Float;
  var ?drag_x:Float;
  var ?drag_y:Float;
}
