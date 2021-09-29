package echo.util.verlet;

import echo.util.verlet.Constraints;
/**
 * A Composite contains Dots and Constraints. It can be thought of as a "Body" in the Verlet simulation.
 */
class Composite {
  public var dots:Array<Dot> = [];
  public var constraints:Array<Constraint> = [];

  public function new() {}

  public function add_dot(?x:Float, ?y:Float) {
    var dot = new Dot(x, y);
    dots.push(dot);
    return dot;
  }

  public inline function remove_dot(dot:Dot) {
    return dots.remove(dot);
  }

  public function add_constraint(constraint:Constraint):Constraint {
    constraints.push(constraint);
    return constraint;
  }

  public inline function remove_constraint(constraint:Constraint):Bool {
    return constraints.remove(constraint);
  }

  public inline function pin(index:Int) add_constraint(new PinConstraint(dots[index]));

  public function bounds(?aabb:AABB):AABB {
    var left = dots[0].x;
    var top = dots[0].y;
    var right = dots[0].x;
    var bottom = dots[0].y;

    for (i in 1...dots.length) {
      if (dots[i].x < left) left = dots[i].x;
      if (dots[i].y < top) top = dots[i].y;
      if (dots[i].x > right) right = dots[i].x;
      if (dots[i].y > bottom) bottom = dots[i].y;
    }

    return aabb == null ? AABB.get_from_min_max(left, top, right, bottom) : aabb.set_from_min_max(left, top, right, bottom);
  }

  public inline function clear() {
    dots.resize(0);
    constraints.resize(0);
  }

  public function toString() return 'Dot Group: {dots: $dots, constraints: $constraints}';
}
