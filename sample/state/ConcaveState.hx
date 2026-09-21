package state;

import echo.Body;
import echo.Material;
import echo.World;
import echo.math.Vector2;
import util.Random;

class ConcaveState extends BaseState {
  var body_count:Int = 24;

  override public function enter(world:World) {
    Main.instance.state_text.text = "Sample: Concave Polygons (Convex Decomposition)";

    var material:Material = {elasticity: 0.2};
    var shapes = [l_shape(20), plus(24), star(5, 24, 10), arrow(30)];

    // Concave Bodies. Setting `decompose` splits the vertices into convex pieces, which the Body uses as its colliders -
    // so each of these ends up with a handful of Shapes that collide as one concave form
    for (i in 0...body_count) {
      world.add(new Body({
        x: Random.range(60, world.width - 60),
        y: Random.range(0, world.height / 2),
        rotation: Random.range(0, 360),
        material: material,
        shape: {
          type: POLYGON,
          vertices: shapes[i % shapes.length],
          decompose: true
        }
      }));
    }

    // A static concave bowl for everything to fall into - the inside of the bowl is hollow, not solid
    world.add(new Body({
      mass: STATIC,
      x: world.width * 0.5,
      y: world.height - 70,
      material: material,
      shape: {
        type: POLYGON,
        vertices: bowl(180, 70, 16),
        decompose: true
      }
    }));

    world.listen();
  }

  override function step(world:World, dt:Float) {
    // Reset any off-screen Bodies
    world.for_each((member) -> {
      if (offscreen(member, world)) {
        member.velocity.set(0, 0);
        member.rotational_velocity = 0;
        member.set_position(Random.range(60, world.width - 60), 0);
      }
    });
  }

  // An "L", centered on its bounds
  static function l_shape(size:Float):Array<Vector2> {
    var t = size * 0.4;
    var h = size * 0.5;
    return [
      new Vector2(-h, -h),
      new Vector2(-h + t, -h),
      new Vector2(-h + t, h - t),
      new Vector2(h, h - t),
      new Vector2(h, h),
      new Vector2(-h, h)
    ];
  }

  // A "+", centered on its origin
  static function plus(size:Float):Array<Vector2> {
    var t = size * 0.2;
    var h = size * 0.5;
    return [
      new Vector2(-t, -h),
      new Vector2(t, -h),
      new Vector2(t, -t),
      new Vector2(h, -t),
      new Vector2(h, t),
      new Vector2(t, t),
      new Vector2(t, h),
      new Vector2(-t, h),
      new Vector2(-t, t),
      new Vector2(-h, t),
      new Vector2(-h, -t),
      new Vector2(-t, -t)
    ];
  }

  static function star(points:Int, outer:Float, inner:Float):Array<Vector2> {
    var vertices = [];
    var step = Math.PI / points;
    for (i in 0...points * 2) {
      var radius = i % 2 == 0 ? outer : inner;
      vertices.push(new Vector2(Math.cos(i * step) * radius, Math.sin(i * step) * radius));
    }
    return vertices;
  }

  static function arrow(size:Float):Array<Vector2> {
    var h = size * 0.5;
    var t = size * 0.18;
    return [
      new Vector2(h, 0),
      new Vector2(0, h),
      new Vector2(0, t),
      new Vector2(-h, t),
      new Vector2(-h, -t),
      new Vector2(0, -t),
      new Vector2(0, -h)
    ];
  }

  // An open topped bowl - the classic case for a concave collider
  static function bowl(width:Float, height:Float, thickness:Float):Array<Vector2> {
    var w = width * 0.5;
    var h = height * 0.5;
    return [
      new Vector2(-w, -h),
      new Vector2(-w + thickness, -h),
      new Vector2(-w + thickness, h - thickness),
      new Vector2(w - thickness, h - thickness),
      new Vector2(w - thickness, -h),
      new Vector2(w, -h),
      new Vector2(w, h),
      new Vector2(-w, h)
    ];
  }
}
