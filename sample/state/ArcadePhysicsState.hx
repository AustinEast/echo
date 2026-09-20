package state;

import echo.Material;
import echo.Body;
import echo.World;
import util.Random;
/**
 * Demonstrates arcade physics (`world.arcade = true`) - Collisions only push Bodies apart and change their velocities. Bodies are never spun by
 * an impact and there is no friction, so shapes slide down the ramp keeping whatever rotation they were given, and the plank never tips.
 *
 * Every other sample runs with the default full physics, so compare this to the Stacking samples to see the difference.
 */
class ArcadePhysicsState extends BaseState {
  var body_count:Int = 60;
  var timer:Float;
  var material:Material;

  override public function enter(world:World) {
    Main.instance.state_text.text = "Sample: Arcade Physics (No Rotation/Friction From Collisions)";
    timer = 0;

    // Switch the World from the default full physics to arcade physics. Collisions will now only affect positions and velocities.
    world.arcade = true;

    // Create a material for all the shapes to share. Friction values have no effect in arcade physics.
    material = {elasticity: 0.2};

    // A ramp on the left for Bodies to slide down
    world.add(new Body({
      mass: STATIC,
      x: world.width * 0.25,
      y: world.height * 0.5,
      rotation: 25,
      material: material,
      shape: {
        type: RECT,
        width: world.width * 0.55,
        height: 16
      }
    }));

    // A floor on the right for Bodies to collect on
    world.add(new Body({
      mass: STATIC,
      x: world.width * 0.72,
      y: world.height - 30,
      material: material,
      shape: {
        type: RECT,
        width: world.width * 0.56,
        height: 16
      }
    }));

    // A bumper at the far right edge
    world.add(new Body({
      mass: STATIC,
      x: world.width - 8,
      y: world.height - 80,
      material: material,
      shape: {
        type: RECT,
        width: 16,
        height: 100
      }
    }));

    // A plank balanced on a peg - in arcade physics it stays perfectly balanced no matter what lands on it
    world.add(new Body({
      mass: STATIC,
      x: world.width * 0.7,
      y: world.height - 90,
      material: material,
      shape: {
        type: POLYGON,
        sides: 3,
        radius: 14
      }
    }));
    world.add(new Body({
      x: world.width * 0.7,
      y: world.height - 108,
      material: material,
      shape: {
        type: RECT,
        width: 120,
        height: 8
      }
    }));

    // Create a listener for collisions between the Physics Bodies
    world.listen();
  }

  override function step(world:World, dt:Float) {
    timer += dt;
    if (timer > 0.5) {
      timer = 0;
      if (world.count < body_count) {
        var type = Random.range_int(0, 3);
        world.add(new Body({
          x: Random.range(20, world.width * 0.3),
          y: -20,
          rotation: Random.range(0, 360),
          // Rotational velocity is still integrated in arcade physics - it just isn't affected by collisions
          // rotational_velocity: Random.range(-90, 90),
          material: material,
          shape: {
            type: type == 0 ? RECT : type == 1 ? CIRCLE : POLYGON,
            radius: Random.range(8, 16),
            width: Random.range(12, 32),
            height: Random.range(12, 32),
            sides: Random.range_int(3, 7)
          }
        }));
      }
    }

    // Reset any off-screen Bodies
    world.for_each((member) -> {
      if (member.is_dynamic() && offscreen(member, world)) {
        member.velocity.set(0, 0);
        member.rotational_velocity = 0;
        member.set_position(Random.range(20, world.width * 0.3), -20);
      }
    });
  }

  override function exit(world:World) {
    super.exit(world);
    // Restore the default full physics for the other samples
    world.arcade = false;
  }
}
