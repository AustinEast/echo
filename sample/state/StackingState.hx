package state;

import echo.Body;
import echo.World;
import glib.FSM;
import glib.Random;

class StackingState extends State<World> {
  var body_count:Int = 100;

  override public function enter(world:World) {
    Main.state_text.text = "Sample: Stacking Boxes";
    // Add a bunch of random Physics Bodies to the World
    for (i in 0...body_count) {
      var b = new Body({
        x: Random.range(0, world.width),
        y: Random.range(0, world.height / 2),
        elasticity: 0.3,
        shape: {
          type: RECT,
          width: Random.range(16, 48),
          height: Random.range(16, 48),
        }
      });
      world.add(b);
    }

    // Add a Physics body at the bottom of the screen for the other Physics Bodies to stack on top of
    // This body has a mass of 0, so it acts as an immovable object
    world.add(new Body({
      mass: 0,
      x: world.width / 2,
      y: world.height - 10,
      elasticity: 0.2,
      shape: {
        type: RECT,
        width: world.width,
        height: 20
      }
    }));

    // Create a listener for collisions between the Physics Bodies
    world.listen();
  }

  override public function exit(world:World) world.clear();
}
