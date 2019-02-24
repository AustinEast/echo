package echo;

import hxmath.math.Vector2;
import glib.Disposable;
import glib.Proxy;
import echo.Shape;
import echo.Echo;
import echo.shape.Rect;
import echo.data.Options;
import echo.data.Types;

class Body implements IEcho implements IDisposable implements IProxy {
  /**
   * Default Body Options
   */
  public static var defaults(get, null):BodyOptions;
  static var ids:Int = 0;
  /**
   * Unique id of the Body
   */
  public var id(default, null):Int;
  /**
   * Body's position on the X axis.
   * Alias for `position.x`
   */
  @:alias(position.x)
  public var x:Float;
  /**
   * Body's position on the Y axis.
   * Alias for `position.y`
   */
  @:alias(position.y)
  public var y:Float;
  /**
   * Body's `Shape`. this `Shape` acts as the Body's Collider, allowing it to be checked for Collisions.
   */
  public var shape(get, set):Null<Shape>;
  /**
   * Flag to set whether the Body collides with other Bodies.
   * If false, this Body will not have its position or velocity affected by other Bodies, but it will still call collision callbacks
   */
  public var solid(get, set):Bool;
  /**
   * Body's mass. Affects how the Body reacts to Collisions and Velocity. The higher a Body's mass, the more resistant it is to those forces.
   * If a Body's mass is set to `0`, it becomes static - unmovable by forces and collisions.
   */
  public var mass(get, set):Float;
  public var position(get, set):Vector2;
  public var rotation(get, set):Float;
  public var elasticity(get, set):Float;
  public var velocity(get, set):Vector2;
  public var acceleration(get, set):Vector2;
  public var rotational_velocity(get, set):Float;
  public var max_velocity(get, set):Vector2;
  public var max_rotational_velocity(get, set):Float;
  public var drag(get, set):Vector2;
  public var gravity_scale(get, set):Float;
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

  function set_mass(value:Float):Float {
    if (value < 0.0001) {
      value = 0;
      inverse_mass = 0;
    }
    else inverse_mass = 1 / value;
    return mass = value;
  }

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
