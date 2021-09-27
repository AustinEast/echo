package echo.util.verlet;

import echo.util.verlet.Composite;
import echo.util.Disposable;
import echo.util.verlet.Constraints;
import echo.math.Vector2;
import echo.data.Options.VerletOptions;
/**
 * A Verlet physics simulation, using Dots, Constraints, and Composites. Useful for goofy Softbody visuals and effects!
 * 
 * This simulation is standalone, meaning it doesn't directly integrate with the standard echo simulation.
 */
class Verlet implements IDisposable {
  /**
   * The Verlet World's position on the X axis.
   */
  public var x:Float;
  /**
   * The Verlet World's position on the Y axis.
   */
  public var y:Float;
  /**
   * Width of the Verlet World, extending right from the World's X position.
   */
  public var width:Float;
  /**
   * Height of the Verlet World, extending down from the World's Y position.
   */
  public var height:Float;
  /**
   * The amount of acceleration applied to each `Dot` every Step.
   */
  public var gravity(default, null):Vector2;

  public var drag:Float;

  public var composites(default, null):Array<Composite> = [];
  /**
   * The amount of iterations that occur each time the Verlet World is stepped. The higher the number, the more stable the Physics Simulation will be, at the cost of performance.
   */
  public var iterations:Int;

  public var bounds_left:Bool = true;

  public var bounds_right:Bool = true;

  public var bounds_top:Bool = true;

  public var bounds_bottom:Bool = true;

  public static function rect(x:Float, y:Float, width:Float, height:Float, stiffness:Float, ?distance:Float):Composite {
    var r = new Composite();
    var tl = r.add_dot(x, y);
    var tr = r.add_dot(x + width, y);
    var br = r.add_dot(x + width, y + height);
    var bl = r.add_dot(x, y + height);

    r.add_constraint(new DistanceConstraint(tl, tr, stiffness, distance));
    r.add_constraint(new DistanceConstraint(tr, br, stiffness, distance));
    r.add_constraint(new DistanceConstraint(br, bl, stiffness, distance));
    r.add_constraint(new DistanceConstraint(bl, tr, stiffness, distance));
    r.add_constraint(new DistanceConstraint(bl, tl, stiffness, distance));

    return r;
  }

  public static function rope(points:Array<Vector2>, stiffness:Float, ?pinned:Array<Int>):Composite {
    var r = new Composite();
    for (i in 0...points.length) {
      var d = new Dot(points[i].x, points[i].y);
      r.dots.push(d);
      if (i > 0) {
        r.constraints.push(new DistanceConstraint(r.dots[i], r.dots[i - 1], stiffness));
      }
      if (pinned != null && pinned.indexOf(i) != -1) {
        r.constraints.push(new PinConstraint(r.dots[i]));
      }
    }
    return r;
  }

  public static function cloth(x:Float, y:Float, width:Float, height:Float, segments:Int, pin_mod:Int, stiffness:Float):Composite {
    var c = new Composite();
    var x_stride = width / segments;
    var y_stride = height / segments;

    for (sy in 0...segments) {
      for (sx in 0...segments) {
        var px = x + sx * x_stride;
        var py = y + sy * y_stride;
        c.dots.push(new Dot(px, py));

        if (sx > 0) c.constraints.push(new DistanceConstraint(c.dots[sy * segments + sx], c.dots[sy * segments + sx - 1], stiffness));

        if (sy > 0) c.constraints.push(new DistanceConstraint(c.dots[sy * segments + sx], c.dots[(sy - 1) * segments + sx], stiffness));
      }
    }

    for (x in 0...segments) {
      if (x % pin_mod == 0) c.add_constraint(new PinConstraint(c.dots[x]));
    }

    return c;
  }

  public function new(options:VerletOptions) {
    width = options.width;
    height = options.height;
    x = options.x == null ? 0 : options.x;
    y = options.y == null ? 0 : options.y;
    gravity = new Vector2(options.gravity_x == null ? 0 : options.gravity_x, options.gravity_y == null ? 0 : options.gravity_y);
    drag = options.drag == null ? .98 : options.drag;
    iterations = options.iterations == null ? 5 : options.iterations;
  }

  public function step(dt:Float, ?colliders:Array<Shape>) {
    for (composite in composites) {
      for (d in composite.dots) {
        // Integrate
        var pos = d.get_position();
        var vel:Vector2 = (pos - d.get_last_position()) * drag;
        d.set_last_position(pos);
        d.set_position(pos + vel + (gravity + d.get_acceleration()) * dt);

        // Check bounds
        if (bounds_bottom && d.y > height + y) d.y = height + y;
        else if (bounds_top && d.y < y) d.y = y;
        if (bounds_left && d.x < x) d.x = x;
        else if (bounds_right && d.x > width + x) d.x = width + x;

        // Check collisions
        if (colliders != null) for (c in colliders) {}
      }

      // Constraints
      var fdt = 1 / iterations;
      for (i in 0...iterations) {
        for (c in composite.constraints) {
          if (c.active) c.step(fdt);
        }
      }
    }
  }

  public function dispose() {
    if (composites != null) for (composite in composites) composite.clear();
    composites = null;
  }
}
