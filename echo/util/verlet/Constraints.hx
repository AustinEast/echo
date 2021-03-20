package echo.util.verlet;

import hxmath.math.Vector2;

using echo.util.Ext;

interface IConstraint {
  public var active:Bool;

  public function step(dt:Float):Void;

  public function get_positions():Array<Vector2>;
}

class DistanceConstraint implements IConstraint {
  public var active = true;
  public var a:Dot;
  public var b:Dot;
  public var stiffness:Float;
  public var distance:Float = 0;

  public function new(a:Dot, b:Dot, stiffness:Float, ?distance:Float) {
    if (a == b) {
      trace("Can't constrain a particle to itself!");
      return;
    }

    this.a = a;
    this.b = b;
    this.stiffness = stiffness;
    if (distance != null) this.distance = distance;
    else this.distance = a.get_position().distanceTo(b.get_position());
  }

  public function step(dt:Float) {
    var ap = a.get_position();
    var bp = b.get_position();
    var normal = ap - bp;
    var m = normal.lengthSq;
    var n = normal * (((distance * distance - m) / m) * stiffness * dt);
    a.set_position(ap + n);
    b.set_position(bp - n);
  }

  public function get_positions():Array<Vector2> {
    return [a.get_position(), b.get_position()];
  }
}

class PinConstraint implements IConstraint {
  public var active = true;
  public var a:Dot;
  public var x:Float;
  public var y:Float;

  public function new(a:Dot, ?x:Float, ?y:Float) {
    this.x = a.x = x == null ? a.x : x;
    this.y = a.y = y == null ? a.y : y;
    this.a = a;
  }

  public function step(dt:Float) {
    a.x = x;
    a.y = y;
  }

  public function get_positions():Array<Vector2> {
    return [a.get_position(), new Vector2(x, y)];
  }
}

class RotationConstraint implements IConstraint {
  public var active = true;
  public var a:Dot;
  public var b:Dot;
  public var c:Dot;
  public var radians:Float;
  public var stiffness:Float;

  public function new(a:Dot, b:Dot, c:Dot, stiffness:Float) {
    this.a = a;
    this.b = b;
    this.c = c;
    this.stiffness = stiffness;
    radians = b.get_position().angle_between_2(a.get_position(), c.get_position());
  }

  public function step(dt:Float) {
    var a_pos = a.get_position();
    var b_pos = b.get_position();
    var c_pos = c.get_position();
    var angle_between = b_pos.angle_between_2(a_pos, c_pos);
    var diff = angle_between - radians;

    if (diff <= -Math.PI) diff += 2 * Math.PI;
    else if (diff >= Math.PI) diff -= 2 * Math.PI;

    diff *= dt * stiffness;

    a.set_position((a_pos - b_pos).rotate(diff, @:privateAccess Echo.cached_zero) + b_pos);
    c.set_position((c_pos - b_pos).rotate(-diff, @:privateAccess Echo.cached_zero) + b_pos);
    a_pos.set(a.x, a.y);
    c_pos.set(c.x, c.y);
    b.set_position((b_pos - a_pos).rotate(diff, @:privateAccess Echo.cached_zero) + a_pos);
    b.set_position((b.get_position() - c_pos).rotate(-diff, @:privateAccess Echo.cached_zero) + c_pos);
  }

  public function get_positions():Array<Vector2> {
    return [a.get_position(), b.get_position(), c.get_position()];
  }
}
