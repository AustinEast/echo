package suite;

import suite.Test.*;
import echo.Echo;
import echo.Body;
import echo.Material;
import echo.World;
import echo.Physics;
import echo.Collisions;
import echo.shape.Rect;
import echo.shape.Circle;
import echo.shape.Polygon;
import echo.math.Vector2;

using echo.util.ext.FloatExt;

class FullPhysicsTest {
  public static function run() {
    test_inertia();
    test_contacts_rect_rect();
    test_contacts_circle();
    test_contacts_polygon_clip();
    test_arcade_no_rotation();
    test_corner_hit_spins();
    test_box_on_slope();
    test_circle_rolls();
    test_symmetric_stack_no_spin();
    test_stack_stability();
    test_listener_override();
    test_fixed_rotation();
    test_kinematic();

  }

  static function test_inertia() {
    section('inertia');
    var box = new Body({shape: {type: RECT, width: 32, height: 32}});
    check('rect mass = 1024', approx(box.mass, 1024));
    // I = m (w^2 + h^2) / 12
    check('rect inertia = m(w²+h²)/12', approx(box.inertia, 1024 * (32 * 32 + 32 * 32) / 12, 0.5), '${box.inertia}');
    check('rect inverse_inertia', approx(box.inverse_inertia, 1 / box.inertia, 1e-9));

    var circle = new Body({shape: {type: CIRCLE, radius: 10}});
    var m = Math.PI * 100;
    check('circle inertia = m r²/2', approx(circle.inertia, m * 100 / 2, 0.5), '${circle.inertia}');

    // A square polygon should match the equivalent rect
    var poly = new Body({
      shape: {
        type: POLYGON,
        vertices: [new Vector2(-16, -16), new Vector2(16, -16), new Vector2(16, 16), new Vector2(-16, 16)]
      }
    });
    check('square polygon inertia matches rect', approx(poly.inertia, box.inertia, 0.5), '${poly.inertia} vs ${box.inertia}');

    // Explicit mass scales inertia proportionally
    var heavy = new Body({mass: 2048, shape: {type: RECT, width: 32, height: 32}});
    check('explicit mass scales inertia', approx(heavy.inertia, box.inertia * 2, 1), '${heavy.inertia}');

    // Offset shape uses parallel axis theorem: I = I_c + m d²
    var offset = new Body({shape: {type: RECT, width: 32, height: 32, offset_x: 10}});
    check('offset shape parallel axis', approx(offset.inertia, box.inertia + 1024 * 100, 1), '${offset.inertia}');

    // Explicit inertia
    var fixed = new Body({inertia: 0, shape: {type: RECT, width: 32, height: 32}});
    check('inertia: 0 -> inverse 0', fixed.inertia == 0 && fixed.inverse_inertia == 0);

    // Static bodies have no inverse inertia
    var stat = new Body({mass: STATIC, shape: {type: RECT, width: 32, height: 32}});
    check('static inverse_inertia = 0', stat.inverse_inertia == 0);

    // No shapes -> inertia = mass
    var point = new Body({mass: 3});
    check('shapeless inertia = mass', point.inertia == 3);

    // Clone preserves inertia
    check('clone preserves inertia', approx(box.clone().inertia, box.inertia, 1e-6));
  }

  static function test_contacts_rect_rect() {
    println('contacts: rect/rect (axis-aligned)');
    var a = Rect.get(0, 0, 20, 20);
    var b = Rect.get(0, 15, 40, 20); // overlaps 5 units vertically, spans wider than a
    var cd = a.collides(b);
    check('collision found', cd != null);
    if (cd == null) return;
    check('normal points down (A -> B)', cd.normal.x == 0 && cd.normal.y == 1, '${cd.normal}');
    check('overlap = 5', approx(cd.overlap, 5));
    check('two contacts', cd.contact_count == 2, '${cd.contact_count}');
    // contacts on the horizontal edges of the overlap region: x from -10..10 (a's width), y midpoint = 7.5
    check('contact x at a\'s edges', approx(cd.contacts[0].x, -10) && approx(cd.contacts[1].x, 10), '${cd.contacts[0]} ${cd.contacts[1]}');
    check('contact y mid-overlap', approx(cd.contacts[0].y, 7.5) && approx(cd.contacts[1].y, 7.5));
    cd.put();
    a.put();
    b.put();
  }

  static function test_contacts_circle() {
    section('contacts: circle');
    var a = Circle.get(0, 0, 10);
    var b = Circle.get(15, 0, 10);
    var cd = a.collides(b);
    check('circle/circle one contact', cd != null && cd.contact_count == 1);
    check('circle/circle contact at 7.5,0', cd != null && approx(cd.contacts[0].x, 7.5) && approx(cd.contacts[0].y, 0), cd == null ? '' : '${cd.contacts[0]}');
    if (cd != null) cd.put();

    var r = Rect.get(0, 20, 40, 20); // top edge at y = 10
    var c = Circle.get(3, 2, 10); // bottom at y = 12 -> 2 overlap
    cd = c.collides(r);
    check('circle/rect one contact', cd != null && cd.contact_count == 1);
    check('circle/rect contact on rect top edge', cd != null && approx(cd.contacts[0].x, 3) && approx(cd.contacts[0].y, 10), cd == null ? '' : '${cd.contacts[0]}');
    if (cd != null) cd.put();
    cd = r.collides(c);
    check('rect/circle (flipped) contact on rect top edge', cd != null && approx(cd.contacts[0].x, 3) && approx(cd.contacts[0].y, 10), cd == null ? '' : '${cd.contacts[0]}');
    if (cd != null) cd.put();

    // Circle vs polygon (rotated rect)
    var rr = Rect.get(0, 20, 40, 20, 45);
    cd = c.collides(rr);
    check('circle/rotated rect has contact', cd != null && cd.contact_count == 1);
    if (cd != null) {
      // contact should lie near the circle's edge in the direction of the normal
      var d = Math.sqrt((cd.contacts[0].x - c.x) * (cd.contacts[0].x - c.x) + (cd.contacts[0].y - c.y) * (cd.contacts[0].y - c.y));
      check('circle/polygon contact within circle radius', d <= 10 && d >= 10 - cd.overlap, '$d overlap ${cd.overlap}');
      cd.put();
    }
    a.put();
    b.put();
    r.put();
    c.put();
    rr.put();
  }

  static function test_contacts_polygon_clip() {
    section('contacts: polygon clipping');
    // Flat floor, box resting flat on top with 2 unit overlap -> 2 contacts on the floor plane at the box's corners
    var floor = Rect.get(0, 50, 200, 20, 0.0001); // tiny rotation forces the polygon path
    var box = Rect.get(0, 32, 20, 20, 0.0001); // bottom at 42, floor top at 40 -> 2 overlap
    var cd = box.collides(floor);
    check('box on floor collides', cd != null);
    if (cd != null) {
      check('box on floor: 2 contacts', cd.contact_count == 2, '${cd.contact_count}');
      check('box on floor: contacts at box corners x', approx(Math.abs(cd.contacts[0].x), 10, 0.05) && approx(Math.abs(cd.contacts[1].x), 10, 0.05),
        '${cd.contacts[0]} ${cd.contacts[1]}');
      check('box on floor: contacts halfway in penetration', approx(cd.contacts[0].y, 41, 0.05), '${cd.contacts[0].y} overlap=${cd.overlap}');
      check('box on floor: normal down', approx(cd.normal.y, 1, 0.001));
      cd.put();
    }

    // Diamond (45deg box) with its bottom corner poking into the floor -> 1 contact near the corner
    var diamond = Rect.get(0, 40 - Math.sqrt(200) + 1, 20, 20, 45); // corner at y ~ 41 (1 unit into floor at y=40)
    cd = diamond.collides(floor);
    check('diamond on floor collides', cd != null);
    if (cd != null) {
      check('diamond on floor: contact(s) near x=0', approx(cd.contacts[0].x, 0, 0.5), '${cd.contacts[0]} count=${cd.contact_count}');
      check('diamond on floor: contact near floor surface', approx(cd.contacts[0].y, 40.5, 0.6), '${cd.contacts[0]}');
      cd.put();
    }

    // Reversed winding polygon still produces contacts
    var cw = Polygon.get_from_vertices(0, 38, 0, [new Vector2(-10, 10), new Vector2(10, 10), new Vector2(10, -10), new Vector2(-10, -10)]);
    var ccw = Polygon.get_from_vertices(0, 38, 0, [new Vector2(-10, -10), new Vector2(10, -10), new Vector2(10, 10), new Vector2(-10, 10)]);
    var floor_poly = Polygon.get_from_rect(floor);
    cd = ccw.collides(floor_poly);
    check('ccw polygon on floor: 2 contacts', cd != null && cd.contact_count == 2, cd == null ? 'null' : '${cd.contact_count}');
    if (cd != null) cd.put();
    cd = cw.collides(floor_poly);
    check('cw polygon on floor: contacts generated', cd != null && cd.contact_count >= 1, cd == null ? 'null' : '${cd.contact_count}');
    if (cd != null) cd.put();

    floor.put();
    box.put();
    diamond.put();
    cw.put();
    ccw.put();
    floor_poly.put();
  }

  static function make_world(arcade:Bool, gravity:Float = 100):World {
    return Echo.start({width: 640, height: 360, gravity_y: gravity, iterations: 5, arcade: arcade});
  }

  static function test_arcade_no_rotation() {
    section('arcade mode');
    var world = make_world(true);
    var floor = world.make({mass: STATIC, x: 320, y: 350, shape: {type: RECT, width: 640, height: 20}});
    // box hanging off a corner of the floor - in full mode it would tip, in arcade it must never rotate
    var box = world.make({x: 320, y: 320, rotation: 30, shape: {type: RECT, width: 30, height: 30}});
    world.listen();
    for (i in 0...120) world.step(1 / 60);
    check('arcade: rotation unchanged', approx(box.rotation, 30, 1e-6) && box.rotational_velocity == 0, '${box.rotation} ${box.rotational_velocity}');
    check('arcade: box rests on floor', box.y < 340 && Math.abs(box.velocity.y) < 5, '${box.y} ${box.velocity.y}');
  }

  static function test_corner_hit_spins() {
    println('full: off-center hit spins');
    var world = make_world(false, 0);
    // Static wall on the right, a box flies into it with its corner leading (rotated 20deg)
    var wall = world.make({mass: STATIC, x: 400, y: 180, shape: {type: RECT, width: 20, height: 300}});
    var box = world.make({x: 300, y: 180, rotation: 20, velocity_x: 200, shape: {type: RECT, width: 40, height: 40}});
    world.listen();
    var spun = false;
    for (i in 0...120) {
      world.step(1 / 60);
      if (Math.abs(box.rotational_velocity) > 1) spun = true;
    }
    check('corner hit produced rotational velocity', spun, '${box.rotational_velocity}');
    check('box bounced/stopped (not through wall)', box.x < 390 - 20, '${box.x}');
  }

  static function test_box_on_slope() {
    section('full: box on slope with friction');
    // Steep slope: box should slide down and tumble/rotate
    var world = make_world(false);
    var slope = world.make({mass: STATIC, x: 320, y: 250, rotation: 30, material: {friction: 0.2, static_friction: 0.3}, shape: {type: RECT, width: 500, height: 20}});
    var box = world.make({x: 200, y: 100, material: {friction: 0.2, static_friction: 0.3}, shape: {type: RECT, width: 24, height: 24}});
    world.listen();
    var max_rot = 0.;
    for (i in 0...180) {
      world.step(1 / 60);
      if (Math.abs(box.rotational_velocity) > max_rot) max_rot = Math.abs(box.rotational_velocity);
    }
    check('box on slope rotated', Math.abs(box.rotation) > 1 || max_rot > 1, 'rot ${box.rotation} maxw $max_rot');
    check('box on slope moved downhill (+x)', box.x > 200, '${box.x}');

    // Shallow slope with high friction: box should (nearly) stick
    var world2 = make_world(false);
    var mat:Material = {friction: 1., static_friction: 1.2};
    world2.make({mass: STATIC, x: 320, y: 250, rotation: 5, material: mat, shape: {type: RECT, width: 500, height: 20}});
    var box2 = world2.make({x: 320, y: 220, rotation: 5, material: mat, shape: {type: RECT, width: 24, height: 24}});
    world2.listen();
    for (i in 0...180) world2.step(1 / 60);
    check('high friction shallow slope: box barely moves', Math.abs(box2.x - 320) < 15, '${box2.x} v=${box2.velocity}');

    // Same shallow slope, no friction: box slides
    var world3 = make_world(false);
    var slick:Material = {friction: 0., static_friction: 0.};
    world3.make({mass: STATIC, x: 320, y: 250, rotation: 5, material: slick, shape: {type: RECT, width: 500, height: 20}});
    var box3 = world3.make({x: 320, y: 220, rotation: 5, material: slick, shape: {type: RECT, width: 24, height: 24}});
    world3.listen();
    for (i in 0...180) world3.step(1 / 60);
    check('frictionless shallow slope: box slides', box3.x - 320 > 30, '${box3.x}');
  }

  static function test_circle_rolls() {
    section('full: circle rolls down slope');
    var world = make_world(false);
    world.make({mass: STATIC, x: 320, y: 250, rotation: 15, shape: {type: RECT, width: 600, height: 20}});
    var ball = world.make({x: 150, y: 150, shape: {type: CIRCLE, radius: 12}});
    world.listen();
    for (i in 0...180) world.step(1 / 60);
    check('ball moved downhill', ball.x > 200, '${ball.x}');
    check('ball is rolling (rotational velocity > 0)', ball.rotational_velocity > 10, '${ball.rotational_velocity}');
    // rolling without slipping: v ≈ w * r (w in rad/s). Allow generous tolerance.
    var w = ball.rotational_velocity.deg_to_rad();
    var v = ball.velocity.length;
    check('rolling roughly matches v = w r', approx(v, w * 12, v * 0.5), 'v=$v w*r=${w * 12}');

    // arcade mode: same setup, ball should NOT roll
    var world2 = make_world(true);
    world2.make({mass: STATIC, x: 320, y: 250, rotation: 15, shape: {type: RECT, width: 600, height: 20}});
    var ball2 = world2.make({x: 150, y: 150, shape: {type: CIRCLE, radius: 12}});
    world2.listen();
    for (i in 0...180) world2.step(1 / 60);
    check('arcade ball does not roll', ball2.rotational_velocity == 0, '${ball2.rotational_velocity}');
  }

  static function test_symmetric_stack_no_spin() {
    section('full: symmetric resting box does not spin');
    var world = make_world(false);
    world.make({mass: STATIC, x: 320, y: 350, shape: {type: RECT, width: 640, height: 20}});
    var box = world.make({x: 320, y: 300, shape: {type: RECT, width: 30, height: 30}});
    world.listen();
    for (i in 0...300) world.step(1 / 60);
    check('resting box rotation ~0', Math.abs(box.rotation) < 0.5, '${box.rotation}');
    check('resting box rotational velocity ~0', Math.abs(box.rotational_velocity) < 1, '${box.rotational_velocity}');
    check('resting box y stable', approx(box.y, 350 - 10 - 15, 1), '${box.y}');
  }

  static function test_stack_stability() {
    section('full: stack stability');
    var world = make_world(false);
    world.make({mass: STATIC, x: 320, y: 350, shape: {type: RECT, width: 640, height: 20}});
    var boxes = [];
    for (i in 0...8) boxes.push(world.make({x: 320, y: 320 - i * 22, shape: {type: RECT, width: 20, height: 20}}));
    world.listen();
    var exploded = false;
    for (i in 0...600) {
      world.step(1 / 60);
      for (b in boxes) if (!Math.isFinite(b.x) || !Math.isFinite(b.rotation) || b.velocity.length > 2000 || Math.abs(b.rotational_velocity) > 5000) exploded = true;
    }
    check('stack did not explode', !exploded);
    var on_floor = 0;
    for (b in boxes) if (b.y < 345 && b.y > 0 && Math.abs(b.x - 320) < 100) on_floor++;
    check('stack boxes still on screen near the floor', on_floor == boxes.length, '$on_floor/${boxes.length}');
    var top = boxes[boxes.length - 1];
    check('top box roughly upright (stack held)', Math.abs(((top.rotation % 90) + 90) % 90) < 10 || Math.abs(((top.rotation % 90) + 90) % 90) > 80, '${top.rotation}');
  }

  static function test_listener_override() {
    section('listener override');
    // arcade world, but a listener with arcade:false -> rotation happens
    var world = make_world(true);
    var slope = world.make({mass: STATIC, x: 320, y: 250, rotation: 15, shape: {type: RECT, width: 600, height: 20}});
    var ball = world.make({x: 150, y: 150, shape: {type: CIRCLE, radius: 12}});
    world.listen(ball, slope, {arcade: false});
    for (i in 0...180) world.step(1 / 60);
    check('listener arcade:false in arcade world rolls', ball.rotational_velocity > 10, '${ball.rotational_velocity}');

    // full world, listener with arcade:true -> no rotation
    var world2 = make_world(false);
    var slope2 = world2.make({mass: STATIC, x: 320, y: 250, rotation: 15, shape: {type: RECT, width: 600, height: 20}});
    var ball2 = world2.make({x: 150, y: 150, shape: {type: CIRCLE, radius: 12}});
    world2.listen(ball2, slope2, {arcade: true});
    for (i in 0...180) world2.step(1 / 60);
    check('listener arcade:true in full world does not roll', ball2.rotational_velocity == 0, '${ball2.rotational_velocity}');
  }

  static function test_fixed_rotation() {
    println('full: inertia 0 (fixed rotation)');
    var world = make_world(false);
    // Frictionless - with inertia 0 the ball can't roll, so with friction it would (correctly) stick to a shallow slope
    var slick:Material = {friction: 0, static_friction: 0};
    world.make({mass: STATIC, x: 320, y: 250, rotation: 15, material: slick, shape: {type: RECT, width: 600, height: 20}});
    var ball = world.make({x: 150, y: 150, inertia: 0, material: slick, shape: {type: CIRCLE, radius: 12}});
    world.listen();
    for (i in 0...180) world.step(1 / 60);
    check('inertia 0 ball does not roll', ball.rotational_velocity == 0, '${ball.rotational_velocity}');
    check('inertia 0 ball still slides', ball.x > 200, '${ball.x}');
  }

  static function test_kinematic() {
    section('full: kinematic');
    var world = make_world(false, 0);
    var platform = world.make({kinematic: true, x: 320, y: 300, velocity_y: -50, shape: {type: RECT, width: 200, height: 20}});
    var box = world.make({x: 330, y: 270, rotation: 10, shape: {type: RECT, width: 30, height: 30}});
    world.listen();
    for (i in 0...60) world.step(1 / 60);
    check('kinematic platform velocity unchanged', platform.velocity.y == -50 && platform.rotational_velocity == 0, '${platform.velocity} ${platform.rotational_velocity}');
    check('box carried upward by platform', box.velocity.y < 0, '${box.velocity.y}');
  }
}
