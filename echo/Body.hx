package echo;

import hxmath.math.Vector2;
import glib.Disposable;
import echo.Shape;

class Body implements IDisposable {
  @:isVar
  public var shape(get, set):Null<Shape>;
  @:isVar
  public var collides(get, set):Bool;
  @:isVar
  public var moves(get, set):Bool;
  @:isVar
  public var solid(get, set):Bool;
  @:isVar
  public var x(get, set):Float;
  @:isVar
  public var y(get, set):Float;
  @:isVar
  public var elasticity(get, set):Float;
  @:isVar
  public var velocity(get, set):Vector2;
  @:isVar
  public var rotational_velocity(get, set):Float;
  @:isVar
  public var max_velocity(get, set):Vector2;
  @:isVar
  public var max_rotational_velocity(get, set):Float;
  @:isVar
  public var drag(get, set):Vector2;
  public var dirty:Bool;

  public function new(?options:BodyOptions) {
    velocity = new Vector2(0, 0);
    load(options);
  }

  public function load(?options:BodyOptions) {
    if (options == null) options = {};
    shape = Shape.get(options.shape);
    x = options.x == null ? 0 : options.x;
    y = options.y == null ? 0 : options.y;
  }

  public function dispose() {
    shape.put();
    velocity = null;
    max_velocity = null;
    drag = null;
  }

  // getters
  function get_shape():Null<Shape> return shape;

  function get_collides():Bool return collides;

  function get_moves():Bool return moves;

  function get_solid():Bool return solid;

  function get_x():Float return x;

  function get_y():Float return y;

  function get_elasticity():Float return elasticity;

  function get_velocity():Vector2 return velocity;

  function get_rotational_velocity():Float return rotational_velocity;

  function get_max_velocity():Vector2 return max_velocity;

  function get_max_rotational_velocity():Float return max_rotational_velocity;

  function get_drag():Vector2 return drag;

  // setters
  function set_shape(value:Null<Shape>):Null<Shape> return shape = value;

  function set_collides(value:Bool):Bool return collides = value;

  function set_moves(value:Bool):Bool return moves = value;

  function set_solid(value:Bool):Bool return solid = value;

  function set_x(value:Float) return x = value;

  function set_y(value:Float) return y = value;

  function set_elasticity(value:Float) return elasticity = value;

  function set_velocity(value:Vector2) return velocity = value;

  function set_rotational_velocity(value:Float) return rotational_velocity = value;

  function set_max_velocity(value:Vector2) return max_velocity = value;

  function set_max_rotational_velocity(value:Float) return max_rotational_velocity = value;

  function set_drag(value:Vector2) return drag = value;
}

typedef BodyOptions = {
  var ?shape:ShapeOptions;
  var ?moves:Bool;
  var ?collides:Bool;
  var ?solid:Bool;
  var ?x:Float;
  var ?y:Float;
  var ?elasticity:Float;
  var ?velocity_x:Float;
  var ?velocity_y:Float;
  var ?rotational_velocity_x:Float;
  var ?rotational_velocity_y:Float;
  var ?max_velocity_x:Float;
  var ?max_velocity_y:Float;
  var ?max_rotational_velocity_x:Float;
  var ?max_rotational_velocity_y:Float;
  var ?drag_x:Float;
  var ?drag_y:Float;
}
