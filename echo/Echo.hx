package echo;

import echo.Body;
import echo.Listener;
import echo.Collisions;
import echo.World;
import echo.data.Types;
import echo.data.Options;

@:expose
class Echo {
  /**
   * Shortcut for creating a new `World`
   * @param options Options for the new `World`
   * @return World
   */
  public static function start(options:WorldOptions):World return new World(options);
  /**
   * Shortcut for creating a new `Body` and adding it to the `World`
   * @param world the `World` to add the `Body` to
   * @param options Options for the new `Body`
   * @return Body
   */
  public static function make(world:World, options:BodyOptions):Body return world.add(new Body(options));
  /**
   * Shortcut for creating a new `Listener` for a set of Bodies in the `World`.
   * @param world the `World` to add the `Listener` to
   * @param a The first `Body` or `Group` to collide against
   * @param b The second `Body` or `Group` to collide against
   * @param options Options to define the Listener's behavior
   * @return Listener
   */
  public static function listen(world:World, ?a:IEcho, ?b:IEcho, ?options:ListenerOptions):Listener {
    if (a == null) return b == null ? world.listeners.add(world, world, options) : world.listeners.add(b, b, options);
    if (b == null) return world.listeners.add(a, a, options);
    return world.listeners.add(a, b, options);
  }
  /**
   * Steps a `World` forward.
   * @param world
   * @param dt
   */
  public static function step(world:World, dt:Float) {
    // TODO: Save World State to History
    var fdt = dt / world.iterations;
    for (i in 0...world.iterations) {
      Physics.step(world, fdt);
      Collisions.query(world);
      Physics.separate(world, fdt);
      Collisions.notify(world);
    }
  }
  /**
   * TODO: Undo a World's last step
   * @param world
   * @return World
   */
  public static function undo(world:World):World {
    return world;
  }
  /**
   * TODO: Redo a World's last step
   * @param world
   * @return World
   */
  public static function redo(world:World):World {
    return world;
  }
  /**
   * TODO: Perform a collision check.
   * @param a
   * @param b
   * @param options
   */
  public static function collide(a:IEcho, b:IEcho, ?options:ListenerOptions) {}
}

interface IEcho {
  public var type(default, null):EchoType;
}
