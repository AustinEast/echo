package state;

import echo.Body;
import echo.World;
import ghost.FSM;
import ghost.Random;

class StaticState extends BaseState {
  var dynamics:Array<Body>;
  var statics:Array<Body>;
  var body_count:Int = 100;
  var static_count:Int = 500;
  var cursor:Body;
  var cursor_speed:Float = 10;
  var timer:Float;

  override public function enter(world:World) {
    Main.instance.state_text.text = "Sample: Optimized Statics";
    timer = 0;

    dynamics = [];
    statics = [];

    for (i in 0...static_count) {
      var b = new Body({
        mass: 0,
        x: (world.width * 0.5) * Math.cos(i) + world.width * 0.5,
        y: (world.height * 0.5) * Math.sin(i) + world.height * 0.5,
        elasticity: 1,
        shape: {
          type: CIRCLE,
          radius: Random.range(2, 4),
        }
      });
      world.add(b);
      statics.push(b);
    }

    cursor = new Body({
      x: world.width * 0.5,
      y: world.height * 0.5,
      shape: {
        type: CIRCLE,
        radius: 16
      }
    });
    world.add(cursor);

    // Create a listener for collisions between the Physics Bodies
    world.listen(dynamics, statics);
    world.listen(cursor, dynamics);
  }

  override function step(world:World, dt:Float) {
    // Move the Cursor Body
    cursor.velocity.set(Main.instance.scene.mouseX - cursor.x, Main.instance.scene.mouseY - cursor.y);
    cursor.velocity *= cursor_speed;

    timer += dt;
    if (timer > 0.1 + Random.range(-0.2, 0.2)) {
      if (world.count < body_count + static_count) dynamics.push(world.add(new Body({
        x: (world.width * 0.5) + Random.range(-world.width * 0.3, world.width * 0.3),
        y: (world.height * 0.5) + Random.range(-world.height * 0.3, world.height * 0.3),
        elasticity: 1,
        shape: {
          type: Random.chance() ? RECT : CIRCLE,
          radius: Random.range(8, 32),
          width: Random.range(8, 48),
          height: Random.range(8, 48),
        }
      })));
      timer = 0;
    }
  }
}
