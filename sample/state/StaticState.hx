package state;

import echo.Group;
import echo.util.QuadTree;
import echo.Body;
import echo.World;
import ghost.FSM;
import ghost.Random;

class StaticState extends State<World> {
  var dynamics:Group;
  var statics:Group;
  var body_count:Int = 100;
  var static_count:Int = 1000;
  var cursor:Body;
  var cursor_speed:Float = 10;
  var timer:Float;

  override public function enter(world:World) {
    Main.instance.state_text.text = "Sample: Optimized Statics";
    Main.instance.iterations_slider.value = 1;
    Main.instance.iterations_slider.onChange();
    timer = 0;

    // lower the number of iterations to improve performance (at the cost of some stability)
    world.iterations = 1;

    dynamics = new Group();
    statics = new Group();

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
      statics.add(b);
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
      if (world.members.length < body_count + static_count) dynamics.add(world.add(new Body({
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

  override public function exit(world:World) {
    Main.instance.iterations_slider.value = 5;
    Main.instance.iterations_slider.onChange();
    world.iterations = 5;
    world.clear();
  }
}
