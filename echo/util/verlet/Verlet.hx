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
class Verlet implements Disposable {
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
   * The amount of iterations that occur on Constraints each time the Verlet World is stepped. The higher the number, the more stable the Physics Simulation will be, at the cost of performance.
   */
  public var iterations:Int;
  /**
   * The fixed Step rate of the Verlet World. The Verlet simulation must be stepped forward at a consistent rate, or it's stability will quickly deteriorate.
   */
  public var fixed_framerate(default, set):Float;

  public var bounds_left:Bool = false;

  public var bounds_right:Bool = false;

  public var bounds_top:Bool = false;

  public var bounds_bottom:Bool = false;
  /**
   * An optional `World` whose Bodies the Verlet World's Dots will collide with. Dots are pushed out of any solid Shape they end up inside of.
   *
   * Note that this is a one-way interaction - Dots are affected by the World's Bodies, but the Bodies are not affected by the Dots.
   */
  public var world:Null<World>;
  /**
   * Shapes that the Verlet World's Dots will collide with. Dots are pushed out of any solid Shape they end up inside of.
   */
  public var colliders:Array<Shape> = [];

  var fixed_accumulator:Float = 0;
  var fixed_dt:Float;
  var collision_shapes:Array<Shape> = [];
  var collision_bounds:Array<AABB> = [];
  var composite_bounds:AABB = AABB.get();
  var body_bounds:AABB = AABB.get();
  var line:Line = Line.get();

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
    fixed_framerate = options.fixed_framerate == null ? 60 : options.fixed_framerate;
    world = options.world;
    if (options.colliders != null) colliders = options.colliders;
  }
  /**
   * Steps the Verlet World forward.
   * @param dt The Delta Time to step the Verlet World forward. The simulation is advanced in fixed increments of `1 / fixed_framerate`.
   * @param colliders Optional extra Shapes for the Dots to collide with during this step (in addition to `colliders` and the Bodies of `world`).
   */
  public function step(dt:Float, ?colliders:Array<Shape>) {
    fixed_accumulator += dt;
    while (fixed_accumulator > fixed_dt) {
      for (composite in composites) {
        for (d in composite.dots) {
          // Integrate
          var pos = d.get_position();
          var vel:Vector2 = (pos - d.get_last_position()) * drag;
          d.set_last_position(pos);
          d.set_position(pos + vel + (gravity + d.get_acceleration()) * fixed_dt);

          // Check bounds
          if (bounds_bottom && d.y > height + y) d.y = height + y;
          else if (bounds_top && d.y < y) d.y = y;
          if (bounds_left && d.x < x) d.x = x;
          else if (bounds_right && d.x > width + x) d.x = width + x;
        }

        // Gather the Shapes this composite could be colliding with
        gather_collision_shapes(composite, colliders);

        // Constraints
        var fdt = 1 / iterations;
        for (i in 0...iterations) {
          for (c in composite.constraints) {
            if (c.active) c.step(fdt);
          }
          // Collisions - push any Dots that have ended up inside a Shape back out to its edge.
          // This is done every iteration so that the Constraints and Collisions settle together.
          if (collision_shapes.length > 0) for (d in composite.dots) collide_dot(d);
        }
      }
      fixed_accumulator -= fixed_dt;
    }
  }
  /**
   * Fills `collision_shapes` with every solid Shape (from `colliders`, `extra`, and the Bodies of `world`) that the composite could be colliding with.
   */
  function gather_collision_shapes(composite:Composite, ?extra:Array<Shape>) {
    collision_shapes.resize(0);
    if (composite.dots.length == 0) return;
    for (s in colliders) if (s.solid) collision_shapes.push(s);
    if (extra != null) for (s in extra) if (s.solid) collision_shapes.push(s);
    if (world != null) {
      composite.bounds(composite_bounds);
      for (body in world.members) {
        if (body.disposed || !body.active || body.shapes.length == 0) continue;
        body.bounds(body_bounds);
        if (body_bounds.overlaps(composite_bounds)) for (s in body.shapes) if (s.solid) collision_shapes.push(s);
      }
    }
    // Cache each Shape's bounds for the cheap per-Dot rejection test
    for (i in 0...collision_shapes.length) {
      if (collision_bounds.length <= i) collision_bounds.push(AABB.get());
      collision_shapes[i].bounds(collision_bounds[i]);
    }
  }
  /**
   * Pushes a Dot out of any Shape in `collision_shapes` that it is inside of, or that it has passed through since the last step.
   */
  function collide_dot(d:Dot) {
    for (i in 0...collision_shapes.length) {
      var s = collision_shapes[i];
      var b = collision_bounds[i];
      var lx = d.dx;
      var ly = d.dy;
      var px = d.x;
      var py = d.y;
      // Cheap bounds check - skip Shapes that the Dot's movement this step can't have touched
      if (Math.max(lx, px) < b.min_x || Math.min(lx, px) > b.max_x || Math.max(ly, py) < b.min_y || Math.min(ly, py) > b.max_y) continue;

      var pos = d.get_position();
      var inside = s.contains(pos);
      var resolved = false;

      // Find where the Dot's path this step entered the Shape, and push the Dot back out through that face.
      // This keeps fast moving Dots from tunneling through thin Shapes (or being pushed out the far side), while preserving their movement along the face.
      var dx = px - lx;
      var dy = py - ly;
      var len = Math.sqrt(dx * dx + dy * dy);
      if (len > 0) {
        var crossed = inside;
        if (!crossed) {
          // The Dot ended up outside the Shape - it only counts as a hit if its path actually passed through the Shape, rather than just touching an edge.
          // Check the path in both directions, since a Dot resting on a face starts its path on that edge (a hit at distance 0).
          line.set(lx, ly, px, py);
          var hit = s.intersect(line);
          if (hit != null) {
            crossed = hit.distance > 0.001 && hit.distance < len - 0.001;
            hit.put();
          }
          if (!crossed) {
            line.set(px, py, lx, ly);
            hit = s.intersect(line);
            if (hit != null) {
              crossed = hit.distance > 0.001 && hit.distance < len - 0.001;
              hit.put();
            }
          }
        }
        if (crossed) {
          // Cast from slightly before the path's start, so that a Dot resting on a face still finds that face as its entry point (rather than the face it would exit through)
          var ext = 0.1 / len;
          line.set(lx - dx * ext, ly - dy * ext, px, py);
          var entry = s.intersect(line);
          if (entry != null) {
            // Orient the face normal to point out of the Shape, then project the Dot onto the face
            var nx = entry.normal.x;
            var ny = entry.normal.y;
            var depth = (px - entry.hit.x) * nx + (py - entry.hit.y) * ny;
            if (depth > 0) {
              depth = -depth;
              nx = -nx;
              ny = -ny;
            }
            d.x = px - nx * depth;
            d.y = py - ny * depth;
            resolved = true;
            entry.put();
          }
        }
      }

      // Otherwise, push the Dot out to the nearest edge of the Shape
      if (!resolved && inside) {
        var edge = s.closest_point_on_edge(pos);
        d.x = edge.x;
        d.y = edge.y;
      }
    }
  }

  public inline function add(composite:Composite):Composite {
    composites.push(composite);
    return composite;
  }

  public inline function remove(composite:Composite):Bool {
    return composites.remove(composite);
  }

  public inline function dispose() {
    if (composites != null) for (composite in composites) composite.clear();
    composites = null;
    world = null;
    colliders = null;
    collision_shapes = null;
    if (composite_bounds != null) composite_bounds.put();
    if (body_bounds != null) body_bounds.put();
    if (collision_bounds != null) for (b in collision_bounds) b.put();
    if (line != null) line.put();
    composite_bounds = null;
    body_bounds = null;
    collision_bounds = null;
    line = null;
  }

  inline function set_fixed_framerate(v:Float) {
    fixed_framerate = Math.max(v, 0);
    fixed_dt = 1 / fixed_framerate;
    return fixed_framerate;
  }
}
