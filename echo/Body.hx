package echo;

import hxmath.math.Vector2;
import ghost.Disposable;
import ghost.Proxy;
import echo.Shape;
import echo.Echo;
import echo.shape.Rect;
import echo.data.Data;
import echo.data.Options;
import echo.data.Types;
/**
 * A `Body` is an Object representing a Physical Body in a `World`.
 *
 * Bodies have position, velocity, mass, an optional collider shape, and many other properties that are used in a `World` simulation.
 */
class Body implements IEcho implements IDisposable implements IProxy {
  /**
   * Default Body Options
   */
  public static var defaults(get, null):BodyOptions;
  static var ids:Int = 0;
  /**
   * Unique id of the Body.
   */
  public var id(default, null):Int;
  /**
   * The Body's position on the X axis.
   *
   * Alias for `position.x`.
   */
  @:alias(position.x)
  public var x:Float;
  /**
   * The Body's position on the Y axis.
   *
   * Alias for `position.y`.
   */
  @:alias(position.y)
  public var y:Float;
  /**
   * The Body's array of `Shape` objects. If it **isn't** null, these `Shape` objects act as the Body's Collider, allowing it to be checked for Collisions.
   */
  public var shapes(get, set):Array<Shape>;
  /**
   * Flag to set how a Body is affected by Collisions.
   *
   * If set to true, the Body will still Collide and move through the world, but it will not be moved by external collision forces.
   * This is useful for things like moving platforms.
   */
  public var kinematic:Bool;
  /**
   * Body's mass. Affects how the Body reacts to Collisions and Velocity.
   *
   * The higher a Body's mass, the more resistant it is to those forces.
   * If a Body's mass is set to `0`, it becomes static - unmovable by forces and collisions.
   */
  public var mass(get, set):Float;
  /**
   * Body's position on the X and Y axis.
   */
  public var position(get, null):Vector2;
  /**
   * Body's current rotational angle. Currently is not implemented.
   */
  public var rotation(get, set):Float;
  /**
   * Value to determine how much of a Body's `velocity` should be retained during collisions (or how much should the `Body` "bounce" in other words).
   */
  public var elasticity(get, set):Float;
  /**
   * The units/second that a `Body` moves.
   */
  public var velocity(get, set):Vector2;
  /**
   * A measure of how fast a `Body` will change it's velocity. Can be thought of the sum of all external forces on an object (such as a World's gravity) during a step.
   */
  public var acceleration(get, set):Vector2;
  /**
   * The units/second that a `Body` will rotate. Currently is not Implemented.
   */
  public var rotational_velocity(get, set):Float;
  /**
   * The maximum velocity range that a `Body` can have.
   *
   * If set to 0, the Body has no restrictions on how fast it can move.
   */
  public var max_velocity(get, set):Vector2;
  /**
   * The maximum rotational velocity range that a `Body` can have. Currently not Implemented.
   *
   * If set to 0, the Body has no restrictions on how fast it can rotate.
   */
  public var max_rotational_velocity(get, set):Float;
  /**
   * A measure of how fast a Body will move its velocity towards 0 when there is no acceleration.
   */
  public var drag(get, set):Vector2;
  /**
   * Percentage value that represents how much a World's gravity affects the Body.
   */
  public var gravity_scale(get, set):Float;
  /**
   * Cached value of 1 divided by the Body's mass. Used in Internal calculations.
   */
  public var inverse_mass(default, null):Float;
  /**
   * Flag to set if the Body is active and will participate in a World's Physics calculations or Collision querys.
   */
  public var active:Bool;
  /**
   * The `World` that this body is attached to. It can only be a part of one `World` at a time.
   */
  @:allow(echo.World)
  public var world(default, null):World;
  /**
   * Dynamic Object to store any user data on the `Body`. Useful for Callbacks.
   */
  public var data:Dynamic;
  /**
   * Enum to determine the whether this Object is a `Body` or a `Group`. This is used in place of Type Casting internally.
   */
  public var echo_type(default, null):EchoType;
  /**
   * Flag to check if the Body collided with something during the step.
   * Used for debug drawing.
   */
  public var collided:Bool;
  @:allow(echo.Physics.step)
  public var last_x(default, null):Float;
  @:allow(echo.Physics.step)
  public var last_y(default, null):Float;

  @:dox(hide)
  @:allow(echo.World, echo.Collisions)
  var cache:{
    x:Float,
    y:Float,
    ?shapes:Array<Shape>,
    ?quadtree_data:QuadTreeData
  };
  /**
   * Creates a new Body.
   * @param options Optional values to configure the new Body
   */
  public function new(?options:BodyOptions) {
    this.id = ++ids;
    active = true;
    echo_type = BODY;
    position = new Vector2(0, 0);
    velocity = new Vector2(0, 0);
    acceleration = new Vector2(0, 0);
    max_velocity = new Vector2(0, 0);
    drag = new Vector2(0, 0);
    cache = {x: 0, y: 0};
    shapes = [];
    load_options(options);
  }
  /**
   * Sets a Body's values from a `BodyOptions` object.
   * @param options
   */
  public function load_options(?options:BodyOptions) {
    options = ghost.Data.copy_fields(options, defaults);
    clear_shapes();
    if (options.shape != null) add_shape(options.shape);
    if (options.shapes != null) for (shape in options.shapes) add_shape(shape);
    position.set(options.x, options.y);
    rotation = options.rotation;
    kinematic = options.kinematic;
    mass = options.mass;
    elasticity = options.elasticity;
    velocity.set(options.velocity_x, options.velocity_y);
    rotational_velocity = options.rotational_velocity;
    max_velocity.set(options.max_velocity_x, options.max_velocity_y);
    max_rotational_velocity = options.max_rotational_velocity;
    drag.set(options.drag_x, options.drag_y);
    gravity_scale = options.gravity_scale;
    last_x = x;
    last_y = y;
  }

  public function add_shape(options:ShapeOptions):Shape {
    var s = Shape.get(options);
    shapes.push(s);
    return s;
  }

  public function remove_shape(shape:Shape):Shape {
    shapes.remove(shape);
    return shape;
  }

  public inline function clear_shapes() {
    for (shape in shapes) shape.put();
    shapes = [];
  }
  /**
   * Adds forces to a Body's acceleration.
   * @param x
   * @param y
   */
  public function push(x:Float = 0, y:Float = 0) {
    acceleration.x += x;
    acceleration.y += y;
  }
  /**
   * If a Body has shapes, it will return an AABB `Rect` representing the bounds of its shapes relative to the Body's Position. If the Body does not have any shapes, this will return `null'.
   * @param rect Optional `Rect` to set the values to. If the Body does not have any shapes, this will not be set.
   * @return Null<Rect>
   */
  public function bounds(?rect:Rect):Null<Rect> {
    if (shapes.length == 0) return null;
    var min_x = 0.;
    var min_y = 0.;
    var max_x = 0.;
    var max_y = 0.;
    for (shape in shapes) {
      if (shape.left < min_x) min_x = shape.left;
      if (shape.top < min_y) min_y = shape.top;
      if (shape.right > max_x) max_x = shape.right;
      if (shape.bottom > max_y) max_y = shape.bottom;
    }
    min_x += position.x;
    min_y += position.y;
    max_x += position.x;
    max_y += position.y;
    return rect == null ? Rect.get_from_min_max(min_x, min_y, max_x, max_y) : rect.set_from_min_max(min_x, min_y, max_x, max_y);
  }

  public inline function remove():Body {
    if (world != null) world.remove(this);
    if (cache.quadtree_data.bounds != null) cache.quadtree_data.bounds.put();
    return this;
  }

  public function refresh_cache() {
    cache.x = x;
    cache.y = y;
    cache.shapes = shapes.copy();
    if (cache.quadtree_data != null) {
      bounds(cache.quadtree_data.bounds);
      if (world != null && mass == 0) world.static_quadtree.update(cache.quadtree_data);
    }
  }
  /**
   * Disposes the Body. DO NOT use the Body after disposing it, as it could lead to null reference errors.
   */
  public function dispose() {
    remove();
    for (shape in shapes) shape.put();
    shapes = null;
    velocity = null;
    max_velocity = null;
    drag = null;
    data = null;
    cache = null;
  }

  function set_mass(value:Float):Float {
    if (value < 0.0001) {
      value = 0;
      inverse_mass = 0;
      refresh_cache();
    }
    else inverse_mass = 1 / value;
    return mass = value;
  }

  static function get_defaults():BodyOptions return {
    kinematic: false,
    mass: 1,
    x: 0,
    y: 0,
    rotation: 0,
    elasticity: 0,
    velocity_x: 0,
    velocity_y: 0,
    rotational_velocity: 0,
    max_velocity_x: 0,
    max_velocity_y: 0,
    max_rotational_velocity: 10000,
    drag_x: 0,
    drag_y: 0,
    gravity_scale: 1
  }
}
