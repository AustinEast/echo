package state;

import echo.Body;
import echo.World;
import ghost.FSM;
import ghost.Random;

class MultiShapeState extends BaseState {
  var body_count:Int = 49;

  override public function enter(world:World) {
    Main.instance.state_text.text = "Sample: Bodies With Multiple Shapes";
    // Add a bunch of random Physics Bodies with multiple shapes to the World
    for (i in 0...body_count) {
      var b = new Body({
        x: Random.range(0, world.width),
        y: Random.range(0, world.height / 2),
        elasticity: 0.3,
        // rotational_velocity: 25,
        rotation: Random.range(0, 360),
        shapes: [
          // {
          //   type: RECT,
          //   width: 32,
          //   radius: 16
          // },
          {
            type: i % 2 == 0 ? CIRCLE : RECT,
            offset_x: 16,
            width: 24,
            radius: 12
          },
          {
            type: i % 2 == 0 ? CIRCLE : RECT,
            offset_x: -16,
            width: 24,
            radius: 12
          },
          {
            type: i % 2 == 0 ? CIRCLE : RECT,
            offset_y: -16,
            width: 24,
            radius: 12
          },
          {
            type: i % 2 == 0 ? CIRCLE : RECT,
            offset_y: 16,
            width: 24,
            radius: 12
          }
        ]
      });
      world.add(b);
    }

    // Add a Physics body at the bottom of the screen for the other Physics Bodies to stack on top of
    // This body has a mass of 0, so it acts as an immovable object
    world.add(new Body({
      mass: 0,
      x: world.width / 2,
      y: world.height - 10,
      elasticity: 0.5,
      shape: {
        type: RECT,
        width: world.width,
        height: 20
      }
    }));

    // Create a listener for collisions between the Physics Bodies
    world.listen();
  }

  override function step(world:World, dt:Float) {
    // Reset any off-screen Bodies
    world.for_each((member) -> {
      // member.rotation += 1 * dt;
      if (offscreen(member, world)) {
        member.velocity.set(0, 0);
        member.set_position(Random.range(0, world.width), 0);
      }
    });
  }
}
