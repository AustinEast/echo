package state;

import echo.Body;
import echo.World;
import ghost.FSM;
import ghost.Random;

class MultiShapeState extends State<World> {
  var body_count:Int = 50;

  override public function enter(world:World) {
    Main.instance.state_text.text = "Sample: Bodies With Multiple Shapes";
    // Add a bunch of random Physics Bodies with multiple shapes to the World
    for (i in 0...body_count) {
      var b = new Body({
        x: Random.range(0, world.width),
        y: Random.range(0, world.height / 2),
        elasticity: 0.3,
        shapes: [
          {
            type: RECT,
            width: 32,
            radius: 16
          },
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
    for (member in world.members) {
      member.rotation += 1 * dt;
      if (offscreen(member, world)) {
        member.velocity.set(0, 0);
        member.position.set(Random.range(0, world.width), 0);
      }
    }
  }

  override public function exit(world:World) world.clear();

  inline function offscreen(b:Body, world:World) {
    var bounds = b.bounds();
    var check = bounds.top > world.height || bounds.right < 0 || bounds.left > world.width;
    bounds.put();
    return check;
  }
}
