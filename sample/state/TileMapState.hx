package state;

import echo.Material;
import echo.Body;
import echo.World;
import util.Random;

class TileMapState extends BaseState {
  var cursor:Body;
  var cursor_speed:Float = 10;
  var body_count:Int = 50;
  var data = [
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
    1, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
    1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
    1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1,
    1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
    1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
    1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1,
    1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1,
    1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  ];
  var tile_width = 32;
  var tile_height = 32;
  var width_in_tiles = 15;
  var height_in_tiles = 12;

  override public function enter(world:World) {
    Main.instance.state_text.text = "Sample: Tilemap Generated Colliders";

    // Create a material for all the shapes to share
    var material:Material = {elasticity: 0.2};

    // Add a bunch of random Physics Bodies to the World
    var bodies = [];
    var hw = world.width / 2;
    var hh = world.height / 2;
    for (i in 0...body_count) {
      var b = new Body({
        x: Random.range(hw - 120, hw + 120),
        y: Random.range(hh - 64, hh + 64),
        material: material,
        rotation: Random.range(0, 360),
        drag_length: 10,
        shape: {
          type: POLYGON,
          radius: Random.range(8, 16),
          sides: Random.range_int(3, 8)
        }
      });
      bodies.push(b);
      world.add(b);
    }

    // Add the Cursor
    var center = world.center();
    cursor = new Body({
      x: center.x,
      y: center.y,
      shape: {
        type: RECT,
        width: 16
      }
    });
    center.put();
    world.add(cursor);

    // Generate an optimized Array of Bodies from Tilemap data
    var tilemap = echo.util.TileMap.generate(data, tile_width, tile_height, width_in_tiles, height_in_tiles, 72, 5);
    for (b in tilemap) world.add(b);

    // Create a listener for collisions between the Physics Bodies
    world.listen(bodies);

    // Create a listener for collisions between the Physics Bodies and the Tilemap Colliders
    world.listen(bodies, tilemap);

    // Create a listener for collisions between the Physics Bodies and the cursor
    world.listen(bodies, cursor);
  }

  override function step(world:World, dt:Float) {
    // Move the Cursor Body
    cursor.velocity.set(Main.instance.scene.mouseX - cursor.x, Main.instance.scene.mouseY - cursor.y);
    cursor.velocity *= cursor_speed;

    // Reset any off-screen Bodies
    world.for_each((member) -> {
      if (member != cursor && offscreen(member, world)) {
        member.velocity.set(0, 0);
        member.set_position(Random.range(0, world.width), 0);
      }
    });
  }
}
