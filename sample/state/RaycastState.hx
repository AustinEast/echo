package state;

import echo.Material;
import echo.Ray;
import echo.Body;
import echo.World;
import util.Random;

/**
 * Casts an endless Ray from the mouse, sweeping around over time, and highlights everything it passes through.
 */
class RaycastState extends BaseState {
  var body_count:Int = 30;
  var dynamics:Array<Body> = [];
  var ray:Ray;
  var angle:Float = 0;

  override public function enter(world:World) {
    Main.instance.state_text.text = "Sample: Raycasting";

    // Create a material for all the shapes to share
    var material:Material = {gravity_scale: 0};

    // Add a ring of slowly spinning Physics Bodies to the World
    for (i in 0...body_count) {
      var b = new Body({
        x: (world.width * 0.35) * Math.cos(i) + world.width * 0.5,
        y: (world.height * 0.35) * Math.sin(i) + world.height * 0.5,
        rotational_velocity: Random.range(-20, 20),
        material: material,
        shape: {
          type: Random.chance() ? POLYGON : RECT,
          radius: Random.range(16, 32),
          width: Random.range(16, 48),
          height: Random.range(16, 48),
          sides: Random.range_int(3, 8)
        }
      });

      dynamics.push(b);
      world.add(b);
    }

    // A Ray has a start and a direction, but no end
    ray = Ray.get(world.width / 2, world.height / 2);
  }

  override function step(world:World, dt:Float) {
    // Sweep the Ray around from the mouse position
    angle += dt * 30;
    ray.start.set(Main.instance.scene.mouseX, Main.instance.scene.mouseY);
    ray.degrees = angle;

    // Draw the Ray itself, then mark every point where it enters a Body
    var debug = Main.instance.debug;
    debug.draw_ray(ray);
    for (intersection in ray.raycast_all(dynamics, world)) {
      var hit = intersection.closest;
      debug.draw_circle(hit.hit.x, hit.hit.y, 4, debug.shape_collided_color);
      // Draw the surface normal at the hit
      debug.draw_line(hit.hit.x, hit.hit.y, hit.hit.x + hit.normal.x * 12, hit.hit.y + hit.normal.y * 12, debug.shape_collided_color);
      intersection.put();
    }
  }

  override function exit(world:World) {
    super.exit(world);
    dynamics.resize(0);
    ray.put();
  }
}
