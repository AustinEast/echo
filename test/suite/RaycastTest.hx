package suite;

import echo.Echo;
import echo.Body;
import echo.Line;
import echo.Ray;
import echo.World;
import echo.shape.Circle;
import echo.shape.Rect;
import echo.util.AABB;
import echo.math.Vector2;
import suite.Test.*;

class RaycastTest {
  public static function run() {
    test_clip();
    test_intersect();
    test_raycast_bodies();
    test_raycast_world();
    test_from_line();
  }

  static function test_clip() {
    section('ray: clip to AABB');
    var ray = Ray.get(0, 0, 1, 0);
    var box = AABB.get_from_min_max(10, -5, 20, 5);
    var l = ray.clip(box);
    check('clip: line starts at the ray start', l != null && l.x == 0 && l.y == 0, '$l');
    check('clip: line ends where the ray leaves the box', l != null && approx(l.dx, 20) && approx(l.dy, 0), '$l');

    box.set_from_min_max(-20, -5, -10, 5);
    check('clip: box behind the ray is missed', ray.clip(box) == null);

    box.set_from_min_max(10, 10, 20, 20);
    check('clip: box off to the side is missed', ray.clip(box) == null);

    ray.set(0, 0, 0, 1); // straight down
    box.set_from_min_max(-5, 10, 5, 30);
    l = ray.clip(box);
    check('clip: axis-aligned direction (x = 0)', l != null && approx(l.dx, 0) && approx(l.dy, 30), '$l');
    box.set_from_min_max(6, 10, 10, 30);
    check('clip: axis-aligned direction outside the slab is missed', ray.clip(box) == null);

    ray.set(0, 0, 1, 1, 5); // diagonal, max_distance 5
    box.set_from_min_max(-100, -100, 100, 100);
    l = ray.clip(box);
    check('clip: max_distance shortens the line', l != null && approx(l.length, 5), '$l');

    ray.set(15, 0, 1, 0);
    box.set_from_min_max(10, -5, 20, 5);
    l = ray.clip(box);
    check('clip: ray starting inside the box runs to its exit', l != null && approx(l.dx, 20), '$l');

    ray.set(0, 0, 1, 0, 5);
    box.set_from_min_max(10, -5, 20, 5);
    check('clip: box further than max_distance is missed', ray.clip(box) == null);

    ray.set(0, 0, 3, 4);
    check('direction is normalized', approx(ray.direction.x, 0.6) && approx(ray.direction.y, 0.8), '${ray.direction}');
    ray.degrees = 90;
    check('degrees setter', approx(ray.direction.x, 0, 1e-9) && approx(ray.direction.y, 1), '${ray.direction}');
    check('point_along', approx(ray.point_along(10).y, 10));
    ray.set_direction(0, 0);
    check('zero direction falls back to +x', ray.direction.x == 1 && ray.direction.y == 0);
    ray.put();
    box.put();
  }

  static function test_intersect() {
    section('ray: intersect shape');
    var ray = Ray.get(0, 0, 1, 0);
    var c = Circle.get(100, 0, 10);
    var hit = ray.intersect(c);
    check('hits circle at its near edge', hit != null && approx(hit.hit.x, 90) && approx(hit.hit.y, 0), '${hit == null ? null : hit.hit}');
    check('distance measured from the ray start', hit != null && approx(hit.distance, 90), '${hit == null ? null : hit.distance}');
    check('data.ray is set and data.line is the ray line', hit != null && hit.ray == ray && hit.line == ray.line);
    if (hit != null) hit.put();

    var r = Rect.get(-100, 0, 20, 20);
    check('shape behind the ray is missed', ray.intersect(r) == null);

    ray.max_distance = 50;
    check('shape past max_distance is missed', ray.intersect(c) == null);
    ray.put();
    c.put();
    r.put();
  }

  static function test_raycast_bodies() {
    section('ray: raycast against bodies (no world)');
    var near = new Body({x: 200, y: 0, shape: {type: CIRCLE, radius: 10}});
    var far = new Body({x: 500, y: 0, shape: {type: RECT, width: 20, height: 20}});
    var behind = new Body({x: -50, y: 0, shape: {type: CIRCLE, radius: 10}});
    var aside = new Body({x: 300, y: 100, shape: {type: CIRCLE, radius: 10}});
    var bodies = [far, aside, behind, near];

    var ray = Ray.get(0, 0, 1, 0);
    var result = Echo.raycast(ray, bodies);
    check('closest body is returned', result != null && result.body == near, '${result == null ? null : result.body}');
    check('closest hit distance', result != null && approx(result.closest.distance, 190), '${result == null ? null : result.closest.distance}');
    if (result != null) result.put();

    var all = Echo.raycast_all(ray, bodies);
    var hit_ids = [for (i in all) i.body.id];
    check('raycast_all hits both bodies along the ray', all.length == 2 && hit_ids.indexOf(near.id) != -1 && hit_ids.indexOf(far.id) != -1, '$hit_ids');
    for (i in all) i.put();

    ray.max_distance = 300;
    all = Echo.raycast_all(ray, bodies);
    check('max_distance excludes the far body', all.length == 1 && all[0].body == near, '${all.length}');
    for (i in all) i.put();

    ray.set(0, 0, -1, 0);
    result = Echo.raycast(ray, bodies);
    check('reversed ray hits the body behind', result != null && result.body == behind);
    if (result != null) result.put();

    result = Echo.raycast(ray, near);
    check('single body miss returns null', result == null);
    ray.set(0, 0, 1, 0);
    result = Echo.raycast(ray, near);
    check('single body hit', result != null && result.body == near);
    if (result != null) result.put();

    check('raycast_floats helper', Echo.raycast_floats(0, 0, 1, 0, bodies) != null);
    check('raycast_vector helper', Echo.raycast_vector(new Vector2(0, 0), 0, bodies) != null);
    check('raycast_vector misses when pointed away', Echo.raycast_vector(new Vector2(0, 0), 90, [near, far]) == null);
    ray.put();
  }

  static function test_raycast_world() {
    section('ray: raycast against a world');
    var world = Echo.start({width: 640, height: 360});
    var a = world.make({x: 320, y: 180, shape: {type: RECT, width: 40, height: 40}});
    var b = world.make({x: 500, y: 180, shape: {type: CIRCLE, radius: 20}});
    var stat = world.make({mass: STATIC, x: 600, y: 180, shape: {type: RECT, width: 20, height: 100}});
    world.step(1 / 60);

    // Ray starting outside the world, pointing across it
    var ray = Ray.get(-100, 180, 1, 0);
    var result = ray.raycast(world.members, world);
    check('endless ray from outside the world hits the closest body', result != null && result.body == a, '${result == null ? null : result.body}');
    check('hit on the near face of the rect', result != null && approx(result.closest.hit.x, 300), '${result == null ? null : result.closest.hit}');
    if (result != null) result.put();

    var all = ray.raycast_all(world.members, world);
    check('raycast_all through the world hits all three bodies', all.length == 3, '${all.length}');
    for (i in all) i.put();

    // Ray pointing away from everything
    ray.set(-100, 180, -1, 0);
    check('ray leaving the world hits nothing', ray.raycast(world.members, world) == null);
    ray.set(320, 0, 0, -1);
    check('ray pointing out of the world hits nothing', ray.raycast(world.members, world) == null);

    // Ray starting inside a body
    ray.set(320, 180, 1, 0);
    result = ray.raycast(world.members, world);
    check('ray starting inside a body still reports it', result != null && result.body == a, '${result == null ? null : result.body}');
    if (result != null) result.put();
    ray.put();
  }

  static function test_from_line() {
    section('ray: from line');
    var line = Line.get(0, 0, 100, 0);
    var far = new Body({x: 300, y: 0, shape: {type: CIRCLE, radius: 10}});
    check('linecast misses the body past its end', Echo.linecast(line, far) == null);
    var ray = Ray.get_from_line(line);
    check('endless ray from the same line hits it', Echo.raycast(ray, far) != null);
    var bounded = Ray.get_from_line(line, false);
    check('bounded ray from the line respects its length', approx(bounded.max_distance, 100) && Echo.raycast(bounded, far) == null);
    ray.put();
    bounded.put();
    line.put();
  }
}
