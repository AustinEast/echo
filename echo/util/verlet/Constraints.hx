package echo.util.verlet;

import echo.math.Vector2;

abstract class Constraint {
  public var active:Bool = true;

  public abstract function step(dt:Float):Void;

  public abstract function position_count():Int;

  public abstract function get_position(i:Int):Vector2;

  public inline function iterator() {
    return new ConstraintIterator(this);
  }

  public inline function get_positions():Array<Vector2> {
    return [for (p in iterator()) p];
  }
}

class ConstraintIterator {
  var c:Constraint;
  var i:Int;

  public inline function new(c:Constraint) {
    this.c = c;
    i = 0;
  }

  public inline function hasNext() {
    return i < c.position_count();
  }

  public inline function next() {
    return c.get_position(i++);
  }
}

class DistanceConstraint extends Constraint {
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
    else this.distance = a.get_position().distance(b.get_position());
  }

  public function step(dt:Float) {
    var ap = a.get_position();
    var bp = b.get_position();
    var normal = ap - bp;
    var m = normal.length_sq;
    var n = normal * (((distance * distance - m) / m) * stiffness * dt);
    a.set_position(ap + n);
    b.set_position(bp - n);
  }

  public inline function position_count() return 2;

  public inline function get_position(i:Int):Vector2 {
    switch (i) {
      case 0:
        return a.get_position();
      case 1:
        return b.get_position();
    }
    throw 'Constraint has no position at index $i.';
  }
}

class PinConstraint extends Constraint {
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

  public inline function position_count():Int return 2;

  public inline function get_position(i:Int):Vector2 {
    switch (i) {
      case 0:
        return a.get_position();
      case 1:
        return new Vector2(x, y);
    }
    throw 'Constraint has no position at index $i.';
  }
}

class RotationConstraint extends Constraint {
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
    radians = b.get_position().radians_between(a.get_position(), c.get_position());
  }

  public function step(dt:Float) {
    var a_pos = a.get_position();
    var b_pos = b.get_position();
    var c_pos = c.get_position();
    var angle_between = b_pos.radians_between(a_pos, c_pos);
    var diff = angle_between - radians;

    if (diff <= -Math.PI) diff += 2 * Math.PI;
    else if (diff >= Math.PI) diff -= 2 * Math.PI;

    diff *= dt * stiffness;

    a.set_position((a_pos - b_pos).rotate(diff) + b_pos);
    c.set_position((c_pos - b_pos).rotate(-diff) + b_pos);
    a_pos.set(a.x, a.y);
    c_pos.set(c.x, c.y);
    b.set_position((b_pos - a_pos).rotate(diff) + a_pos);
    b.set_position((b.get_position() - c_pos).rotate(-diff) + c_pos);
  }

  public inline function position_count() return 3;

  public inline function get_position(i:Int):Vector2 {
    switch (i) {
      case 0:
        return a.get_position();
      case 1:
        return b.get_position();
      case 2:
        return c.get_position();
    }
    throw 'Constraint has no position at index $i.';
  }
}
