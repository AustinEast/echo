package state;

import echo.data.Options.ListenerOptions;
import echo.Material;
import echo.Body;
import echo.World;
import util.Random;

class ListenerState extends BaseState {

  override public function enter(world:World) {
    Main.instance.state_text.text = "Sample: Collision Listener";

    // Create a material for all the shapes to share
    var material:Material = {elasticity: 0.7};

    var bodyA = new Body({
        x: Random.range(60, world.width - 60),
        y: Random.range(0, world.height / 2),
        rotation: Random.range(0, 360),
        material: material,
        shapes: [
			{
				type: POLYGON,
				radius: Random.range(16, 32),
				width: Random.range(16, 48),
				height: Random.range(16, 48),
				sides: Random.range_int(3, 8),
				offset_y: -10,
			},
			{
				type: POLYGON,
				radius: Random.range(16, 32),
				width: Random.range(16, 48),
				height: Random.range(16, 48),
				sides: Random.range_int(3, 8),
				offset_y: 10,
			}
		]
      });
    world.add(bodyA);

    // Add a Physics body at the bottom of the screen for the other Physics Bodies to stack on top of
    // This body has a mass of 0, so it acts as an immovable object
	var bodyB = new Body({
		mass: STATIC,
		x: world.width / 5,
		y: world.height - 40,
		material: material,
		rotation: 5,
		shape: {
		  type: RECT,
		  width: world.width,
		  height: 20
		}
	  });
    world.add(bodyB);

    var dbgOpts:ListenerOptions = {
      enter: (a, b, data) -> {
		trace('bodyA == listener `a`: ${bodyA == a}');
		trace('bodyA shape == data `shape a`: ${bodyA.shape == data[0].sa}');
		trace('bodyB == listener `b`: ${bodyB == b}');
		trace('bodyB shape == data `shape b`: ${bodyB.shape == data[0].sb}');
      },
    };

    // Create a listener for collisions between the Physics Bodies
    world.listen(bodyA, bodyB, dbgOpts);
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