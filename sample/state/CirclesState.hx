package state;

import echo.Body;
import echo.World;
import ghost.FSM;
import ghost.Random;

class CirclesState extends State<World> {
  var body_count:Int = 100;
  var cursor:Body;
  var cursor_speed:Float = 10;
  var timer:Float;

  override public function enter(world:World) {
    Main.instance.state_text.text = "Sample: Circle/Box Collisions";
    timer = 0;
    // Add some platforms for the bodies to bounce off of
    // Setting the Mass to 0 makes them unmovable
    for (i in 0...4) {
      world.add(new Body({
        mass: 0,
        x: (world.width / 4) * i + (world.width / 8),
        y: world.height - 30,
        elasticity: 0.3,
        shape: {
          type: RECT,
          width: world.width / 8,
          height: 10
        }
      }));
    }

    cursor = new Body({
      x: Main.instance.scene.mouseX,
      y: Main.instance.scene.mouseY,
      shape: {
        type: CIRCLE,
        radius: 16
      }
    });
    world.add(cursor);

    // Create a listener for collisions between the Physics Bodies
    world.listen();
  }

  override function step(world:World, dt:Float) {
    // Move the Cursor Body
    cursor.velocity.set(Main.instance.scene.mouseX - cursor.x, Main.instance.scene.mouseY - cursor.y);
    cursor.velocity *= cursor_speed;

    timer += dt;
    if (timer > 0.3 + Random.range(-0.2, 0.2)) {
      if (world.members.length < body_count) world.add(new Body({
        x: Random.range(0, world.width),
        elasticity: 0.3,
        shape: {
          type: Random.chance() ? RECT : CIRCLE,
          radius: Random.range(4, 32),
          width: Random.range(8, 64),
          height: Random.range(8, 64),
        }
      }));

      timer = 0;
    }
    // Reset any off-screen Bodies
    for (member in world.members) {
      // Exclude the cursor
      if (member.id == cursor.id) continue;
      if (offscreen(member, world)) {
        member.velocity.set(0, 0);
        member.position.set(Random.range(0, world.width), 0);
      }
    }
  }

  override public function exit(world:World) world.clear();

  inline function offscreen(b:Body, world:World) {
    var bounds = b.bounds();
    var check = bounds.top > world.height || bounds.right < 0 || bounds.left > world.width;
    bounds.put();
    return check;
  }
}
