package state;

import hxd.Key;
import echo.Body;
import echo.World;
import util.Random;

class PolygonState extends BaseState {
  var body_count:Int = 100;
  var boi:Body;

  override public function enter(world:World) {
    Main.instance.state_text.text = "Sample: Stacking Polygons";
    // Add a bunch of random Physics Bodies to the World
    for (i in 0...body_count) {
      var scale = Random.range(0.3, 1);
      var b = new Body({
        x: Random.range(60, world.width - 60),
        y: Random.range(0, world.height / 2),
        elasticity: 0.7,
        rotation: Random.range(0, 360),
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
      mass: 0,
      x: world.width / 5,
      y: world.height - 40,
      elasticity: 0.7,
      rotation: 5,
      shape: {
        type: RECT,
        width: world.width / 2,
        height: 20
      }
    }));

    world.add(new Body({
      mass: 0,
      x: world.width - world.width / 5,
      y: world.height - 40,
      elasticity: 0.7,
      rotation: -5,
      shape: {
        type: RECT,
        width: world.width / 2,
        height: 20
      }
    }));

    boi = world.add(new Body({
      kinematic: true,
      drag_length: 50,
      max_velocity_length: 30,
      shape: {
        type: RECT,
        width: 32
      }
    }));

    // Create a listener for collisions between the Physics Bodies
    world.listen();
  }

  override function step(world:World, dt:Float) {
    boi.acceleration.set(0, 0);
    if (Key.isDown(Key.W)) {
      boi.push(10, 0, true, POSITION);
    }

    if (Key.isDown(Key.A)) {
      boi.rotation += 20 * dt;
    }

    if (Key.isDown(Key.D)) {
      boi.rotation -= 20 * dt;
    }

    // Reset any off-screen Bodies
    world.for_each((member) -> {
      if (offscreen(member, world)) {
        member.velocity.set(0, 0);
        member.set_position(Random.range(0, world.width), 0);
      }
    });
  }
}
