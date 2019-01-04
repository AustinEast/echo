package echo;

import hxmath.math.Vector2;
import echo.shape.Shape;

class Body {
  public var shape:Shape;
  public var collides:Bool;
  public var moves:Bool;
  public var solid:Bool;
  @:isVar
  public var x(get, set):Float;
  @:isVar
  public var y(get, set):Float;
  @:isVar
  public var elasticity(get, set):Float;
  public var velocity(get, null):Vector2;
  public var drag(get, null):Vector2;
  public var dirty:Bool;

  public function new(?options:BodyOptions) {
    load(options);
  }

  public function load(?options:BodyOptions) {
    if (options == null) options = {};
    if (options.shape != null) shape = Shape.get(options.shape);
  }

  public function dispose() {
    shape.put();
  }

  // getters
  function get_x():Float return x;

  function get_y():Float return y;

  function get_elasticity():Float return elasticity;

  function get_velocity():Vector2 return velocity;

  function get_drag():Vector2 return drag;

  // setters
  function set_x(value:Float) return x = value;

  function set_y(value:Float) return y = value;

  function set_elasticity(value:Float) return elasticity = value;
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
  var ?drag_x:Float;
  var ?drag_y:Float;
}
