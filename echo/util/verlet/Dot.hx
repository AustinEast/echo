package echo.util.verlet;

import echo.math.Vector2;
/**
 * The Dot is the basic building block of the Verlet simulation, representing a single moving point.
 * 
 * Each Dot stores its latest position, acceleration, and prior position (from the last time the Verlet simulation stepped forward).
 */
class Dot {
  /**
   * The Dot's X position.
   */
  public var x:Float;
  /**
   * The Dot's Y position.
   */
  public var y:Float;
  /**
   * The Dot's last X position.
   */
  public var dx:Float;
  /**
   * The Dot's last Y position.
   */
  public var dy:Float;
  /**
   * The Dot's X acceleration.
   */
  public var ax:Float;
  /**
   * The Dot's Y acceleration.
   */
  public var ay:Float;

  public function new(x:Float = 0, y:Float = 0) {
    dx = this.x = x;
    dy = this.y = y;
    ax = ay = 0;
  }

  public inline function push(x:Float = 0, y:Float = 0) {
    ax += x;
    ay += y;
  }

  public inline function get_position() return new Vector2(x, y);

  public inline function get_last_position() return new Vector2(dx, dy);

  public inline function get_acceleration() return new Vector2(ax, ay);

  public inline function set_position(v:Vector2) {
    x = v.x;
    y = v.y;
  }

  public inline function set_last_position(v:Vector2) {
    dx = v.x;
    dy = v.y;
  }

  public inline function set_acceleration(v:Vector2) {
    ax = v.x;
    ay = v.y;
  }

  public function toString() return 'Dot: {x: $x, y: $y}';
}
