package state;

import echo.Body;
import echo.World;
import glib.FSM;
import glib.Random;

class StackingState extends State<World> {
  var body_count:Int = 200;

  override public function enter(parent:World) {
    Main.state_text.text = "Sample: Stacking Boxes";
    // Add a bunch of random Physics Bodies to the World
    for (i in 0...body_count) {
      var b = new Body({
        x: Random.range(0, parent.width),
        y: Random.range(0, parent.height / 2),
        elasticity: 0.3,
        shape: {
          type: RECT,
          width: Random.range(8, 32),
          height: Random.range(8, 32),
        }
      });
      parent.add(b);
    }

    // Add a Physics body at the bottom of the screen for the other Physics Bodies to stack on top of
    // This body has a mass of 0, so it acts as an immovable object
    parent.add(new Body({
      mass: 0,
      x: parent.width / 2,
      y: parent.height - 10,
      elasticity: 0.2,
      shape: {
        type: RECT,
        width: parent.width,
        height: 20
      }
    }));
  }

  override public function exit(parent:World) parent.clear();
}
