package state;

import echo.Material;
import hxd.Key;
import echo.Body;
import echo.World;
import util.Random;

class PolygonState extends BaseState {
  var body_count:Int = 100;

  override public function enter(world:World) {
    Main.instance.state_text.text = "Sample: Stacking Polygons";

    // Create a material for all the shapes to share
    var material:Material = {elasticity: 0.7};

    // Add a bunch of random Physics Bodies to the World
    for (i in 0...body_count) {
      var scale = Random.range(0.3, 1);
      var b = new Body({
        x: Random.range(60, world.width - 60),
        y: Random.range(0, world.height / 2),
        rotation: Random.range(0, 360),
        material: material,
        shape: {
          type: POLYGON,
          radius: Random.range(16, 32),
          width: Random.range(16, 48),
          height: Random.range(16, 48),
          sides: Random.range_int(3, 8),
          scale_x: scale,
          scale_y: scale
        }
      });
      world.add(b);
    }

    // Add a Physics body at the bottom of the screen for the other Physics Bodies to stack on top of
    // This body has a mass of 0, so it acts as an immovable object
    world.add(new Body({
      mass: STATIC,
      x: world.width / 5,
      y: world.height - 40,
      material: material,
      rotation: 5,
      shape: {
        type: RECT,
        width: world.width / 2,
        height: 20
      }
    }));

    world.add(new Body({
      mass: STATIC,
      x: world.width - world.width / 5,
      y: world.height - 40,
      material: material,
      rotation: -5,
      shape: {
        type: RECT,
        width: world.width / 2,
        height: 20
      }
    }));

    // Create a listener for collisions between the Physics Bodies
    world.listen();
  }

  override function step(world:World, dt:Float) {
    // Reset any off-screen Bodies
    world.for_each((member) -> {
      if (offscreen(member, world)) {
        member.velocity.set(0, 0);
        member.set_position(Random.range(0, world.width), 0);
      }
    });
  }
}
