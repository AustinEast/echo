package suite;

import echo.Echo;
import echo.Body;
import echo.World;
import echo.Material;
import suite.Test.*;

/**
 * Cross-checks the QuadTree broadphase and Listener pair generation against a brute force O(N²) scan, every frame.
 */
class BroadphaseTest {
  static var seed = 4242;

  static function rnd():Float {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    return seed / 0x7fffffff;
  }

  static function range(min:Float, max:Float) return min + rnd() * (max - min);

  static function key(a:Body, b:Body) return a.id < b.id ? '${a.id}:${b.id}' : '${b.id}:${a.id}';

  static var diag_world:World;

  /**
   * Every pair of Bodies (one from `a`, one from `b`) whose Shapes actually collide - computed without the QuadTree.
   */
  static function brute_force(world:World, a:Array<Body>, b:Array<Body>):Map<String, Bool> {
    var pairs = new Map<String, Bool>();
    var wb = world.center().to_aabb(true);
    for (x in a) for (y in b) {
      if (x == y || x.disposed || y.disposed || !x.active || !y.active || x.shapes.length == 0 || y.shapes.length == 0) continue;
      if (x.is_static() && y.is_static()) continue;
      if (!(x.layer_mask.is_empty() || y.layer_mask.is_empty() || (x.layer_mask.contains(y.layers) && y.layer_mask.contains(x.layers)))) continue;
      // Bodies whose (padded) stored bounds are outside the World bounds are not tracked by the QuadTree, so they never collide - mirror that
      var in_world = @:privateAccess x.quadtree_data.bounds.overlaps(wb) && @:privateAccess y.quadtree_data.bounds.overlaps(wb);
      if (!in_world) continue;
      var xb = x.bounds();
      var yb = y.bounds();
      if (xb.overlaps(yb)) {
        var hit = false;
        for (sx in x.shapes) for (sy in y.shapes) {
          var cd = sx.collides(sy);
          if (cd != null) {
            hit = true;
            cd.put();
          }
        }
        if (hit) pairs.set(key(x, y), true);
      }
      xb.put();
      yb.put();
    }
    wb.put();
    return pairs;
  }

  static function listener_pairs(world:World, dupes:Array<Int>):Map<String, Bool> {
    var pairs = new Map<String, Bool>();
    for (l in world.listeners) for (c in l.collisions) {
      var k = key(c.a, c.b);
      if (pairs.exists(k)) dupes[0]++;
      pairs.set(k, true);
    }
    return pairs;
  }

  static function compare(name:String, expected:Map<String, Bool>, actual:Map<String, Bool>):Bool {
    var missing = [];
    var extra = [];
    for (k in expected.keys()) if (!actual.exists(k)) missing.push(k);
    for (k in actual.keys()) if (!expected.exists(k)) extra.push(k);
    if (missing.length > 0 || extra.length > 0) {
      println('    $name: missing=${missing} extra=${extra}');
      for (k in missing.concat(extra)) diagnose(k);
      return false;
    }
    return true;
  }

  static function diagnose(k:String) {
    var ids = k.split(':').map(Std.parseInt);
    var a:Body = null;
    var b:Body = null;
    for (m in diag_world.members) {
      if (m.id == ids[0]) a = m;
      if (m.id == ids[1]) b = m;
    }
    if (a == null || b == null) return;
    var ab = a.shape.collides(b.shape);
    var ba = b.shape.collides(a.shape);
    var abb = a.bounds();
    var bbb = b.bounds();
    println('      ${a.shape} mass=${a.mass} bounds=$abb stored=${@:privateAccess a.quadtree_data.bounds}');
    println('      ${b.shape} mass=${b.mass} bounds=$bbb stored=${@:privateAccess b.quadtree_data.bounds}');
    println('      a.collides(b)=${ab == null ? "null" : "overlap " + ab.overlap} b.collides(a)=${ba == null ? "null" : "overlap " + ba.overlap}');
    if (ab != null) ab.put();
    if (ba != null) ba.put();
    abb.put();
    bbb.put();
  }

  public static function run() {
    section('broadphase: all-vs-all');
    // Everything vs everything (a == b), mixed shapes, two static slopes. `separate: false` keeps the post-step state identical to what the last query saw.
    var world = Echo.start({width: 640, height: 360, gravity_y: 100, iterations: 3});
    world.quadtree.max_depth = 4;
    world.quadtree.max_contents = 8;
    var material:Material = {elasticity: 0.3};
    for (i in 0...120) {
      var t = Std.int(range(0, 3));
      world.add(new Body({
        x: range(0, 640),
        y: range(0, 200),
        rotation: range(0, 360),
        material: material,
        shape: {type: t == 0 ? RECT : t == 1 ? CIRCLE : POLYGON, radius: range(8, 24), width: range(8, 40), height: range(8, 40), sides: Std.int(range(3, 8))}
      }));
    }
    world.add(new Body({mass: STATIC, x: 160, y: 300, rotation: 8, shape: {type: RECT, width: 320, height: 20}}));
    world.add(new Body({mass: STATIC, x: 480, y: 300, rotation: -8, shape: {type: RECT, width: 320, height: 20}}));
    world.listen(null, null, {separate: false});
    diag_world = world;
    var frames = 240;
    var mismatches = 0;
    var dupes = [0];
    var max_pairs = 0;
    for (f in 0...frames) {
      // Reposition before stepping, so the compared state is exactly what the last query saw
      for (m in world.members) if (m.is_dynamic() && m.y > 400) {
        m.velocity.set(0, 0);
        m.set_position(range(0, 640), 0);
      }
      world.step(1 / 60);
      var actual = listener_pairs(world, dupes);
      max_pairs = Std.int(Math.max(max_pairs, Lambda.count(actual)));
      if (!compare('frame $f', brute_force(world, world.members, world.members), actual)) mismatches++;
    }
    check('pairs match brute force for $frames frames', mismatches == 0, '$mismatches mismatching frames');
    check('no duplicate pairs reported', dupes[0] == 0, '${dupes[0]}');
    check('scene actually produced collisions', max_pairs > 50, '$max_pairs');
    check('quadtree subdivided', !world.quadtree.leaf, 'root is a single leaf');

    section('broadphase: groups');
    // Two overlapping groups (some bodies in both), a static body in one group only, a single body vs a group, and collision layers
    var world2 = Echo.start({width: 400, height: 400, gravity_y: 0, iterations: 1});
    var group_a = [];
    var group_b = [];
    var all = [];
    for (i in 0...80) {
      var b = world2.add(new Body({
        x: range(0, 400),
        y: range(0, 400),
        velocity_x: range(-60, 60),
        velocity_y: range(-60, 60),
        shape: {type: i % 2 == 0 ? RECT : CIRCLE, radius: range(8, 20), width: range(8, 40), height: range(8, 40)}
      }));
      if (i % 3 == 0) b.layers.add(1);
      if (i % 5 == 0) b.layer_mask.add(1);
      all.push(b);
      if (i < 50) group_a.push(b);
      if (i >= 30) group_b.push(b); // bodies 30..49 are in both groups
    }
    var wall = world2.add(new Body({mass: STATIC, x: 200, y: 200, shape: {type: RECT, width: 60, height: 200}}));
    group_a.push(wall);
    var single = world2.add(new Body({x: 100, y: 100, velocity_x: 40, shape: {type: CIRCLE, radius: 30}}));
    world2.listen(group_a, group_b, {separate: false});
    world2.listen(single, all, {separate: false});
    diag_world = world2;
    mismatches = 0;
    dupes[0] = 0;
    var wall_hits = 0;
    for (f in 0...frames) {
      world2.step(1 / 60);
      for (m in world2.members) if (m.is_dynamic()) {
        if (m.x < 0 || m.x > 400) m.velocity.x *= -1;
        if (m.y < 0 || m.y > 400) m.velocity.y *= -1;
      }
      var expected = brute_force(world2, group_a, group_b);
      for (k in brute_force(world2, [single], all).keys()) expected.set(k, true);
      var actual = listener_pairs(world2, dupes);
      for (k in actual.keys()) if (k.split(':').indexOf('${wall.id}') != -1) wall_hits++;
      if (!compare('frame $f', expected, actual)) mismatches++;
    }
    check('group pairs match brute force for $frames frames', mismatches == 0, '$mismatches mismatching frames');
    check('no duplicate pairs reported', dupes[0] == 0, '${dupes[0]}');
    check('static body in group a collides with dynamic bodies in group b', wall_hits > 0);
  }
}
