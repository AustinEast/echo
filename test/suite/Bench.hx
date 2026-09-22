package suite;

import echo.util.QuadTree;
import suite.Test.*;
import echo.Echo;
import echo.Body;
import echo.World;
import echo.Material;

/**
 * Benchmarks the engine's hot path on scenes matching the sample's Stacking Polygons / Stacking Boxes states, plus a
 * scene that settles and stays put. Each scene runs with and without the `sleeping_bodies` optimization.
 *
 * Build and run with `haxe bench.hxml` (optionally `-cmd node bin/bench.js arcade|full [stats]`).
 */
class Bench {
  // Deterministic LCG so arcade/full runs see identical scenes
  static var seed = 12345;

  static function rnd():Float {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    return seed / 0x7fffffff;
  }

  static function range(min:Float, max:Float) return min + rnd() * (max - min);

  static function range_int(min:Int, max:Int) return Std.int(range(min, max));

  static function polygon_scene(arcade:Bool, sleeping:Bool = false):World {
    seed = 12345;
    var world = Echo.start({width: 640, height: 360, gravity_y: 100, iterations: 5, arcade: arcade, sleeping_bodies: sleeping});
    world.quadtree.max_depth = 3;
    world.static_quadtree.max_depth = 3;
    world.quadtree.max_contents = 20;
    world.static_quadtree.max_contents = 20;
    var material:Material = {elasticity: 0.7};
    for (i in 0...100) {
      var scale = range(0.3, 1);
      world.add(new Body({
        x: range(60, world.width - 60),
        y: range(0, world.height / 2),
        rotation: range(0, 360),
        material: material,
        shape: {type: POLYGON, radius: range(16, 32), sides: range_int(3, 8), scale_x: scale, scale_y: scale}
      }));
    }
    world.add(new Body({mass: STATIC, x: world.width / 5, y: world.height - 40, material: material, rotation: 5, shape: {type: RECT, width: world.width / 2, height: 20}}));
    world.add(new Body({mass: STATIC, x: world.width - world.width / 5, y: world.height - 40, material: material, rotation: -5, shape: {type: RECT, width: world.width / 2, height: 20}}));
    world.listen();
    return world;
  }

  static function stacking_scene(arcade:Bool, sleeping:Bool = false):World {
    seed = 777;
    var world = Echo.start({width: 640, height: 360, gravity_y: 100, iterations: 5, arcade: arcade, sleeping_bodies: sleeping});
    world.quadtree.max_depth = 3;
    world.static_quadtree.max_depth = 3;
    world.quadtree.max_contents = 20;
    world.static_quadtree.max_contents = 20;
    var material:Material = {elasticity: 0.7};
    for (i in 0...149) {
      world.add(new Body({
        x: range(60, world.width - 60),
        y: range(0, world.height / 2),
        material: material,
        shape: {type: RECT, width: range(16, 48), height: range(16, 48)}
      }));
    }
    world.add(new Body({mass: STATIC, x: world.width / 2, y: world.height - 10, material: {elasticity: 0.2}, shape: {type: RECT, width: world.width, height: 20}}));
    world.listen();
    return world;
  }

  /**
   * A heap of boxes dropped into a pen, which comes to rest and stays there - the case the sleeping optimization is for.
   */
  static function settling_scene(arcade:Bool, sleeping:Bool = false):World {
    seed = 24680;
    var world = Echo.start({width: 640, height: 360, gravity_y: 100, iterations: 5, arcade: arcade, sleeping_bodies: sleeping});
    world.quadtree.max_depth = 3;
    world.static_quadtree.max_depth = 3;
    world.quadtree.max_contents = 20;
    world.static_quadtree.max_contents = 20;
    var material:Material = {elasticity: 0.2};
    for (i in 0...120) {
      world.add(new Body({
        x: range(120, world.width - 120),
        y: range(-400, world.height / 2),
        material: material,
        shape: {type: RECT, width: range(16, 32), height: range(16, 32)}
      }));
    }
    world.add(new Body({mass: STATIC, x: world.width / 2, y: world.height - 10, material: material, shape: {type: RECT, width: world.width, height: 20}}));
    world.add(new Body({mass: STATIC, x: 100, y: world.height - 80, material: material, shape: {type: RECT, width: 20, height: 160}}));
    world.add(new Body({mass: STATIC, x: world.width - 100, y: world.height - 80, material: material, shape: {type: RECT, width: 20, height: 160}}));
    world.listen();
    return world;
  }

  static function run(name:String, world:World, frames:Int):Float {
    // Reset any off-screen bodies like the sample does
    var t0 = haxe.Timer.stamp();
    for (f in 0...frames) {
      world.step(1 / 60);
      for (m in world.members) {
        if (m.is_dynamic() && (m.y > world.height + 50 || m.x < -50 || m.x > world.width + 50)) {
          m.velocity.set(0, 0);
          m.set_position(range(0, world.width), 0);
        }
      }
    }
    var ms = (haxe.Timer.stamp() - t0) * 1000 / frames;
    if (args_has('stats')) {
      QtStats.report('  dynamic qt', world.quadtree);
      QtStats.report('  static qt', world.static_quadtree);
    }
    var pairs = 0;
    for (l in world.listeners) pairs += l.collisions.length;
    var asleep = 0;
    var dynamics = 0;
    for (m in world.members) if (m.is_dynamic()) {
      dynamics++;
      if (m.sleeping) asleep++;
    }
    println('$name: ${Math.round(ms * 1000) / 1000} ms/step  (pairs at end: $pairs, asleep: $asleep/$dynamics)');
    return ms;
  }

  static var g_args:Array<String> = [];
  static function args_has(s:String) return g_args.indexOf(s) != -1;

  static function main() {
    var frames = 600;
    var args = Test.args();
    g_args = args;
    var only = args.length > 0 && args[0] != 'stats' ? args[0] : null;
    // warmup
    run('warmup', polygon_scene(true), 120);
    if (only == null || only == 'arcade') {
      run('polygons arcade          ', polygon_scene(true), frames);
      run('polygons arcade sleeping ', polygon_scene(true, true), frames);
      run('stacking arcade          ', stacking_scene(true), frames);
      run('stacking arcade sleeping ', stacking_scene(true, true), frames);
      run('settling arcade          ', settling_scene(true), frames);
      run('settling arcade sleeping ', settling_scene(true, true), frames);
    }
    if (only == null || only == 'full') {
      run('polygons full            ', polygon_scene(false), frames);
      run('polygons full   sleeping ', polygon_scene(false, true), frames);
      run('stacking full            ', stacking_scene(false), frames);
      run('stacking full   sleeping ', stacking_scene(false, true), frames);
      run('settling full            ', settling_scene(false), frames);
      run('settling full   sleeping ', settling_scene(false, true), frames);
    }
  }
}

/**
 * Reports how the QuadTree has subdivided - useful for spotting a broadphase that has degraded to a single leaf.
 */
private class QtStats {
  static function walk(q:QuadTree, depth:Int, acc:Array<Int>) {
    if (q.leaf) { acc.push(q.contents_count); return; }
    for (c in q.children) if (c != null) walk(c, depth + 1, acc);
  }
  public static function report(name:String, q:QuadTree) {
    var leaves = [];
    walk(q, 0, leaves);
    var max = 0; var sum = 0;
    for (l in leaves) { sum += l; if (l > max) max = l; }
    println('$name: leaves=${leaves.length} total_entries=$sum max_leaf=$max (entries per leaf: $leaves)');
  }
}
