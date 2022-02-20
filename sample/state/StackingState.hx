package state;

import echo.Material;
import echo.Body;
import echo.World;
import util.Random;

class StackingState extends BaseState {
  var body_count:Int = 149;

  override public function enter(world:World) {
    Main.instance.state_text.text = "Sample: Stacking Boxes";

    // Create a material for all the shapes to share
    var material:Material = {elasticity: 0.7};

    // Add a bunch of random Physics Bodies to the World
    for (i in 0...body_count) {
      var b = new Body({
        x: Random.range(60, world.width - 60),
        y: Random.range(0, world.height / 2),
        material: material,
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
      mass: STATIC,
      x: world.width / 2,
      y: world.height - 10,
      material: {elasticity: 0.2},
      shape: {
        type: RECT,
        width: world.width,
        height: 20
      }
    }));

    // Create a listener for collisions between the Physics Bodies
    world.listen();
  }
}
