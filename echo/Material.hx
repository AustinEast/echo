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
   * 
   */
  public var density:Float = 1;
  /**
   * TODO
   */
  @:dox(hide)
  @:noCompletion
  public var friction:Float = 0;
  /**
   * TODO
   */
  @:dox(hide)
  @:noCompletion
  public var static_friction:Float = 0;
  /**
   * Percentage value that represents how much a World's gravity affects the Body.
   */
  public var gravity_scale:Float = 1;
}
