package echo;

import glib.Proxy;
import hxmath.math.Vector2;

typedef LineType = {
  var x:Float;
  var y:Float;
  var dx:Float;
  var dy:Float;
}

class Line implements IProxy {
  public var x(get, set):Float;
  public var y(get, set):Float;
  public var start:Vector2;
  public var dx(get, set):Float;
  public var dy(get, set):Float;
  public var end:Vector2;
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

  // getters
  function get_x():Float return start.x;

  function get_y():Float return start.y;

  function get_dx():Float return end.x;

  function get_dy():Float return end.y;

  function get_length():Float return start.distanceTo(end);

  // setters
  function set_x(value:Float):Float return start.x = value;

  function set_y(value:Float):Float return start.y = value;

  function set_dx(value:Float):Float return end.x = value;

  function set_dy(value:Float):Float return end.y = value;
}
