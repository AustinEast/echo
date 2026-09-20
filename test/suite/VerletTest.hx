package suite;

import suite.Test.*;
import echo.Echo;
import echo.Body;
import echo.World;
import echo.shape.Rect;
import echo.shape.Circle;
import echo.shape.Polygon;
import echo.math.Vector2;
import echo.util.verlet.Verlet;
import echo.util.verlet.Composite;
import echo.util.verlet.Constraints;

class VerletTest {
  public static function run() {
    test_contains();
    test_closest_point_on_edge();
    test_dots_vs_colliders();
    test_dots_vs_world();
    test_cloth_drapes();

  }

  static function test_contains() {
    section('contains');
    var p = Polygon.get(0, 0, 4, 10); // diamond-ish square with radius 10
    check('polygon contains center', p.contains(new Vector2(0, 0)));
    check('polygon does not contain far point', !p.contains(new Vector2(50, 50)));
    check('polygon does not contain point just outside', !p.contains(new Vector2(0, -11)));
    var r = Rect.get(0, 0, 20, 20, 45);
    check('rotated rect contains center', r.contains(new Vector2(0, 0)));
    check('rotated rect contains point on its (rotated) axis', r.contains(new Vector2(0, 13)));
    check('rotated rect excludes former corner', !r.contains(new Vector2(9.5, 9.5)));
    var c = Circle.get(0, 0, 5);
    check('circle contains', c.contains(new Vector2(3, 3)) && !c.contains(new Vector2(4, 4)));
    p.put();
    r.put();
    c.put();
  }

  static function test_closest_point_on_edge() {
    section('closest_point_on_edge');
    var r = Rect.get(0, 0, 20, 10); // x -10..10, y -5..5
    var e = r.closest_point_on_edge(new Vector2(30, 2));
    check('rect: outside point clamps to edge', approx(e.x, 10) && approx(e.y, 2), '$e');
    e = r.closest_point_on_edge(new Vector2(2, 4));
    check('rect: inside point snaps to nearest (bottom) edge', approx(e.x, 2) && approx(e.y, 5), '$e');
    e = r.closest_point_on_edge(new Vector2(-9, 0));
    check('rect: inside point snaps to nearest (left) edge', approx(e.x, -10) && approx(e.y, 0), '$e');

    var c = Circle.get(0, 0, 10);
    e = c.closest_point_on_edge(new Vector2(3, 4));
    check('circle: inside point projects to radius', approx(e.x, 6) && approx(e.y, 8), '$e');
    e = c.closest_point_on_edge(new Vector2(0, 0));
    check('circle: center gives a point on the edge', approx(Math.sqrt(e.x * e.x + e.y * e.y), 10), '$e');

    var p = Polygon.get_from_vertices(0, 0, 0, [new Vector2(-10, -10), new Vector2(10, -10), new Vector2(10, 10), new Vector2(-10, 10)]);
    e = p.closest_point_on_edge(new Vector2(8, 1));
    check('polygon: inside point snaps to nearest edge', approx(e.x, 10) && approx(e.y, 1), '$e');
    e = p.closest_point_on_edge(new Vector2(20, 20));
    check('polygon: outside point snaps to corner', approx(e.x, 10) && approx(e.y, 10), '$e');

    var rr = Rect.get(0, 0, 20, 20, 90);
    e = rr.closest_point_on_edge(new Vector2(0, 8));
    check('rotated rect uses polygon path', approx(e.x, 0, 0.01) && approx(e.y, 10, 0.01), '$e');
    r.put();
    c.put();
    p.put();
    rr.put();
  }

  static function test_dots_vs_colliders() {
    section('dots vs colliders');
    var verlet = new Verlet({width: 200, height: 200, gravity_y: 100});
    var floor = Rect.get(100, 150, 200, 20); // top at 140
    verlet.colliders.push(floor);
    var rope = Verlet.rope([for (i in 0...5) new Vector2(50 + i * 10, 50)], 0.9);
    verlet.add(rope);
    for (i in 0...180) verlet.step(1 / 60);
    var all_above = true;
    for (d in rope.dots) if (d.y > 140.01) all_above = false;
    check('rope dots rest on collider floor (y <= 140)', all_above, '${rope.dots}');
    var resting = false;
    for (d in rope.dots) if (approx(d.y, 140, 0.5)) resting = true;
    check('rope actually reached the floor', resting, '${rope.dots}');

    // Non-solid shapes are ignored
    var verlet2 = new Verlet({width: 200, height: 200, gravity_y: 100});
    var ghost = Rect.get(100, 150, 200, 20);
    ghost.solid = false;
    verlet2.colliders.push(ghost);
    var rope2 = Verlet.rope([for (i in 0...5) new Vector2(50 + i * 10, 50)], 0.9);
    verlet2.add(rope2);
    for (i in 0...180) verlet2.step(1 / 60);
    check('non-solid collider is ignored', rope2.dots[0].y > 160, '${rope2.dots[0]}');

    // extra colliders passed to step
    var verlet3 = new Verlet({width: 200, height: 200, gravity_y: 100});
    var rope3 = Verlet.rope([for (i in 0...5) new Vector2(50 + i * 10, 50)], 0.9);
    verlet3.add(rope3);
    for (i in 0...180) verlet3.step(1 / 60, [floor]);
    check('step(dt, colliders) also collides', rope3.dots[0].y <= 140.01, '${rope3.dots[0]}');

    // A very fast dot must not tunnel through a thin shape
    var verlet4 = new Verlet({width: 400, height: 400, gravity_y: 100});
    var thin = Rect.get(200, 300, 400, 4); // 4px thick, top at 298
    verlet4.colliders.push(thin);
    var c4 = new Composite();
    var bullet = c4.add_dot(200, 0);
    bullet.dy = -60; // 60px/frame downward
    verlet4.add(c4);
    for (i in 0...60) verlet4.step(1 / 60);
    check('fast dot does not tunnel through thin shape', bullet.y <= 298.01, '${bullet}');
    thin.put();
    floor.put();
    ghost.put();
  }

  static function test_dots_vs_world() {
    section('dots vs world bodies');
    var world = Echo.start({width: 200, height: 200});
    var slope = world.make({mass: STATIC, x: 100, y: 120, rotation: 20, shape: {type: RECT, width: 200, height: 10}});
    var ball = world.make({mass: STATIC, x: 60, y: 60, shape: {type: CIRCLE, radius: 15}});
    var verlet = new Verlet({width: 200, height: 200, gravity_y: 100, world: world});
    verlet.bounds_bottom = true;
    // A dot dropped directly above the ball should stop on it
    var c = new Composite();
    var on_ball = c.add_dot(60, 20);
    verlet.add(c);
    // A dot dropped onto the slope should slide down along it
    var c2 = new Composite();
    var on_slope = c2.add_dot(30, 20);
    verlet.add(c2);

    var max_depth = 0.;
    var touched = false;
    var fell_through = false;
    for (i in 0...120) {
      verlet.step(1 / 60);
      var p = on_slope.get_position();
      if (slope.shape.contains(p)) {
        touched = true;
        var e = slope.shape.closest_point_on_edge(p);
        var depth = Math.sqrt((e.x - p.x) * (e.x - p.x) + (e.y - p.y) * (e.y - p.y));
        if (depth > max_depth) max_depth = depth;
      }
      // Once on the slope, the dot must stay above the slope's underside while it is still over the slope
      if (touched && p.x < 190 && p.y > slope.shape.bottom) fell_through = true;
    }
    check('slope dot never sinks into the slope', max_depth < 0.5, 'max depth $max_depth');
    check('slope dot never falls through the slope', touched && !fell_through, 'touched=$touched ${on_slope}');
    var d = Math.sqrt((on_ball.x - 60) * (on_ball.x - 60) + (on_ball.y - 60) * (on_ball.y - 60));
    check('dot rests on circle body', d >= 14.9 && on_ball.y < 60, 'dist=$d ${on_ball}');
    check('dot never inside slope body', !slope.shape.contains(on_slope.get_position()) || approx(Math.abs(slope.shape.closest_point_on_edge(on_slope.get_position()).y - on_slope.y), 0, 0.01), '${on_slope}');
    check('dot slid down the slope (+x)', on_slope.x > 40, '${on_slope}');

    // Inactive body is ignored
    ball.active = false;
    var c3 = new Composite();
    var through = c3.add_dot(60, 20);
    verlet.add(c3);
    for (i in 0...120) verlet.step(1 / 60);
    check('inactive body ignored', through.y > 80, '${through}');
    verlet.dispose();
  }

  static function test_cloth_drapes() {
    section('cloth drapes over body');
    var world = Echo.start({width: 300, height: 300});
    var box = world.make({mass: STATIC, x: 150, y: 200, shape: {type: RECT, width: 60, height: 60}});
    var verlet = new Verlet({width: 300, height: 300, gravity_y: 100, world: world});
    var cloth = Verlet.cloth(130, 50, 40, 40, 5, 100, 0.9); // fully above the box's top (x 120..180)
    // Verlet.cloth always pins its first dot - remove the pins so the cloth falls freely
    cloth.constraints = cloth.constraints.filter(c -> !(c is PinConstraint));
    verlet.add(cloth);
    for (i in 0...300) verlet.step(1 / 60);
    var inside = 0;
    for (d in cloth.dots) if (d.x > 120.5 && d.x < 179.5 && d.y > 170.5 && d.y < 229.5) inside++;
    check('no cloth dots inside the box', inside == 0, '$inside inside');
    var on_top = 0;
    for (d in cloth.dots) if (approx(d.y, 170, 0.5) && d.x >= 120 && d.x <= 180) on_top++;
    var min_y = 1e9, max_y = -1e9, min_x = 1e9, max_x = -1e9;
    for (d in cloth.dots) { if (d.y < min_y) min_y = d.y; if (d.y > max_y) max_y = d.y; if (d.x < min_x) min_x = d.x; if (d.x > max_x) max_x = d.x; }
    check('some cloth dots rest on the box top', on_top > 0, '$on_top x[$min_x..$max_x] y[$min_y..$max_y]');
    verlet.dispose();
  }
}
