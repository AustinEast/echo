package echo;

import echo.util.Proxy;
import hxmath.math.Vector2;
/**
 * TODO
 */
class Line implements IProxy {
  @:alias(start.x)
  public var x:Float;
  @:alias(start.y)
  public var y:Float;
  public var start:Vector2;
  @:alias(end.x)
  public var dx:Float;
  @:alias(end.y)
  public var dy:Float;
  public var end:Vector2;
  @:alias(start.distanceTo(end))
  public var length(get, null):Float;

  public function new(x:Float = 0, y:Float = 0, dx:Float = 1, dy:Float = 1) {
    start = new Vector2(x, y);
    end = new Vector2(dx, dy);
  }

  public function contains(v:Vector2):Bool {
    // Find the slope
    var m = (dy - y) / (dx - y);
    var b = y - m * x;
    return v.y == m * v.x + b;
  }
}
