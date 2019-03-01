package state;

import echo.Group;
import echo.util.QuadTree;
import echo.Body;
import echo.World;
import glib.FSM;
import glib.Random;

class StaticState extends State<World> {
  var dynamics:Group;
  var statics:Group;
  var body_count:Int = 50;
  var static_count:Int = 500;
  var cursor:Body;
  var cursor_speed:Float = 10;
  var timer:Float;

  override public function enter(world:World) {
    Main.state_text.text = "Sample: Optimized Statics";
    timer = 0;

    dynamics = new Group();
    statics = new Group();

    for (i in 0...static_count) {
      var b = new Body({
        mass: 0,
        x: (world.width * 0.5) * Math.cos(i) + world.width * 0.5,
        y: (world.height * 0.5) * Math.sin(i) + world.height * 0.5,
        elasticity: 0.3,
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

  override function update(world:World, dt:Float) {
    // Move the Cursor Body
    cursor.velocity.set(Main.scene.mouseX - cursor.x, Main.scene.mouseY - cursor.y);
    cursor.velocity *= cursor_speed;

    timer += dt;
    if (timer > 0.3 + Random.range(-0.2, 0.2)) {
      if (world.members.length < body_count + static_count) dynamics.add(world.add(new Body({
          x: (world.width * 0.5) + Random.range(-48, 48),
          y: (world.height * 0.5) + Random.range(-48, 48),
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

  override public function exit(world:World) world.clear();
}
