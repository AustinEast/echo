package echo;

import echo.math.Vector2;
import echo.util.BitMask;
/**
 * A Structure that describes the physical properties of a `Body`.
 */
@:structInit
class Material {
  public static var global:Material = {};
  /**
   * Value to determine how much of a Body's `velocity` should be retained during collisions (or how much should the `Body` "bounce" in other words).
   */
  public var elasticity:Float = 0;
  /**
   * The density of the Body. Used to automatically calculate the Body's `mass` and `inertia` from the volume of it's shapes.
   */
  public var density:Float = 1;
  /**
   * Coefficient of dynamic (kinetic) friction. Determines how much a Body resists sliding along a surface it is already moving across.
   *
   * Only used when Collisions are resolved with full physics (`arcade = false`).
   */
  public var friction:Float = 0.3;
  /**
   * Coefficient of static friction. Determines how much force is required to get a resting Body to start sliding along a surface.
   *
   * Only used when Collisions are resolved with full physics (`arcade = false`).
   */
  public var static_friction:Float = 0.4;
  /**
   * Percentage value that represents how much a World's gravity affects the Body.
   */
  public var gravity_scale:Float = 1;
}
