package echo;

import hxmath.math.Vector2;
import echo.util.QuadTree;
import echo.Listener;
import echo.data.Data;
import echo.data.Options;
import haxe.ds.Vector;
/**
 * A `World` is an Object representing the state of a Physics simulation and it configurations. 
 */
 @:using(echo.Echo)
class World extends Group {
  /**
   * Width of the World, extending right from the World's X position.
   */
  public var width:Float;
  /**
   * Height of the World, extending down from the World's Y position.
   */
  public var height:Float;
  /**
   * The World's position on the X axis.
   */
  public var x:Float;
  /**
   * The World's position on the Y axis.
   */
  public var y:Float;
  /**
   * The amount of acceleration applied to each `Body` member every Step.
   */
  public var gravity(default, null):Vector2;
  public var quadtree:QuadTree;
  /**
   * The amount of iterations that occur each time the World is stepped. The higher the number, the more stable the Physics Simulation will be, at the cost of performance.
   */
  public var listeners:Listeners;
  public var iterations:Int;
  public var history:Vector<{bodies:Array<Body>, collisions:Array<Collision>}>;

  public function new(options:WorldOptions) {
    super(options.members);
    width = options.width < 1 ? throw("World must have a width of at least 1") : options.width;
    height = options.height < 1 ? throw("World must have a width of at least 1") : options.height;
    x = options.x == null ? 0 : options.x;
    y = options.y == null ? 0 : options.y;
    gravity = new Vector2(options.gravity_x == null ? 0 : options.gravity_x, options.gravity_y == null ? 0 : options.gravity_y);
    quadtree = QuadTree.get();
    listeners = new Listeners(this, options.listeners);
    iterations = options.iterations == null ? 5 : options.iterations;
  }

  /**
   * Clears the World's members and listeners.
   */
  override function clear() {
    super.clear();
    listeners.clear();
  }
  /**
   * Disposes the World. DO NOT use the World after disposing it, as it could lead to null reference errors.
   */
  override function dispose() {
    super.dispose();
    gravity = null;
    quadtree.put();
    listeners.dispose();
    listeners = null;
    history = null;
  }
}
