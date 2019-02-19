package state;

import echo.Body;
import echo.World;
import glib.FSM;
import glib.Random;

class CirclesState extends State<World> {
  var body_count:Int = 50;
  var cursor:Body;
  var cursor_speed:Float = 10;

  override public function enter(parent:World) {
    Main.state_text.text = "Sample: Circle/Box Collisions";
    // Add a bunch of Physics Bodies to the World
    // And split them between the two groups
    for (i in 0...body_count) {
      var b = new Body({
        x: Random.range(0, parent.width),
        y: Random.range(0, parent.height / 3),
        elasticity: 0.3,
        shape: {
          type: Random.chance() ? RECT : CIRCLE,
          radius: Random.range(4, 16),
          width: Random.range(8, 32),
          height: Random.range(8, 32),
        }
      });
      parent.add(b);
    }

    // Add some platforms for the bodies to bounce off of
    // Setting the Mass to 0 makes them unmovable
    for (i in 0...4) {
      parent.add(new Body({
        mass: 0,
        x: (parent.width / 4) * i + (parent.width / 8),
        y: parent.height - 30,
        elasticity: 0.3,
        shape: {
          type: RECT,
          width: parent.width / 8,
          height: 10
        }
      }));
    }

    cursor = new Body({
      x: Main.scene.mouseX,
      y: Main.scene.mouseY,
      shape: {
        type: CIRCLE,
        radius: 16
      }
    });
    parent.add(cursor);
  }

  override function update(parent:World, dt:Float) {
    // Move the Cursor Body
    cursor.velocity.set(Main.scene.mouseX - cursor.x, Main.scene.mouseY - cursor.y);
    cursor.velocity *= cursor_speed;
    // Reset any off-screen Bodies
    for (member in parent.members) {
      // Exclude the cursor
      if (member.id == cursor.id) continue;
      if (member.y + member.shape.top > parent.height
        || member.x + member.shape.right < 0
        || member.x + member.shape.left > parent.width) {
        member.velocity.set(0, 0);
        member.position.set(Random.range(0, parent.width), 0);
      }
    }
  }

  override public function exit(parent:World) parent.clear();
}
