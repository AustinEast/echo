package state;

import echo.data.Options.ListenerOptions;
import echo.Material;
import echo.Body;
import echo.World;
import util.Random;

class OverlappingSpawnState extends BaseState {

  override public function enter(world:World) {
    Main.instance.state_text.text = "Sample: Collision Listener";

    // Create a material for all the shapes to share
    var material:Material = {elasticity: 0.7};

    var body = new Body({
        x: 200,
        y: 50,
        rotation: 0,
        material: material,
        shape: {
				type: POLYGON,
				radius: 16,
				width: 16,
				height: 16,
				sides: 5,
				offset_y: 0,
			}
      });
    world.add(body);

	body = new Body({
        x: 200,
        y: 53,
        rotation: 0,
        material: material,
        shape: {
				type: POLYGON,
				radius: 10,
				width: 10,
				height: 10,
				sides: 5,
				offset_y: 0,
			}
      });
    world.add(body);

    // Add a Physics body at the bottom of the screen for the other Physics Bodies to stack on top of
    // This body has a mass of 0, so it acts as an immovable object
	var floor = new Body({
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
    world.add(floor);

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