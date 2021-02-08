package state;

import echo.Body;
import echo.World;
import util.Random;

class TileMapState2 extends BaseState {
  var cursor:Body;
  var cursor_speed:Float = 10;
  var body_count:Int = 30;
  var data = [
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 19, 20, -1, -1, -1, -1, -1, -1, -1, 15, 19, 18, 1, 1, 1, -1, 2, 3, -1, -1, -1, -1, -1, -1, -1, -1, -1, 21,
    1, 1, -1, 15, 16, 0, -1, -1, -1, -1, -1, -1, -1, -1, 23, 1, 1, -1, -1, -1, -1, -1, -1, -1, 4, 5, 6, 7, -1, 10, 1, 1, -1, -1, -1, -1, -1, -1, -1, 17, 18,
    19, 20, -1, 8, 1, 1, -1, -1, 10, 11, -1, -1, -1, -1, -1, -1, -1, -1, 21, 1, 1, -1, -1, 23, 24, -1, -1, 12, -1, -1, -1, -1, -1, 23, 1, 1, 3, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, 12, -1, 1, 1, 1, 6, 7, -1, -1, -1, -1, 4, 5, 1, 3, -1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
  ];
  var tile_width = 32;
  var tile_height = 32;
  var width_in_tiles = 15;
  var height_in_tiles = 12;

  override public function enter(world:World) {
    Main.instance.state_text.text = "Sample: Tilemap Generated Colliders (Slopes/Custom)";
    // Add a bunch of random Physics Bodies to the World
    var bodies = [];
    var hw = world.width / 2;
    var hh = world.height / 2;
    for (i in 0...body_count) {
      var b = new Body({
        x: Random.range(hw - 120, hw + 120),
        y: Random.range(world.y + 64, world.y + 72),
        elasticity: 0.2,
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
    var tilemap = echo.util.TileMap.generate(data, tile_width, tile_height, width_in_tiles, height_in_tiles, 72, 5, 1, [
      {
        index: 2,
        slope_direction: TopLeft
      },
      {
        index: 4,
        slope_direction: TopLeft,
        slope_shape: {angle: Gentle, size: Thin}
      },
      {
        index: 5,
        slope_direction: TopLeft,
        slope_shape: {angle: Gentle, size: Thick}
      },
      {
        index: 10,
        slope_direction: TopLeft,
        slope_shape: {angle: Sharp, size: Thin}
      },
      {
        index: 8,
        slope_direction: TopLeft,
        slope_shape: {angle: Sharp, size: Thick}
      },
      {
        index: 3,
        slope_direction: TopRight
      },
      {
        index: 7,
        slope_direction: TopRight,
        slope_shape: {angle: Gentle, size: Thin}
      },
      {
        index: 6,
        slope_direction: TopRight,
        slope_shape: {angle: Gentle, size: Thick}
      },
      {
        index: 11,
        slope_direction: TopRight,
        slope_shape: {angle: Sharp, size: Thin}
      },
      {
        index: 9,
        slope_direction: TopRight,
        slope_shape: {angle: Sharp, size: Thick}
      },
      {
        index: 15,
        slope_direction: BottomLeft
      },
      {
        index: 17,
        slope_direction: BottomLeft,
        slope_shape: {angle: Gentle, size: Thin}
      },
      {
        index: 18,
        slope_direction: BottomLeft,
        slope_shape: {angle: Gentle, size: Thick}
      },
      {
        index: 23,
        slope_direction: BottomLeft,
        slope_shape: {angle: Sharp, size: Thin}
      },
      {
        index: 21,
        slope_direction: BottomLeft,
        slope_shape: {angle: Sharp, size: Thick}
      },
      {
        index: 16,
        slope_direction: BottomRight
      },
      {
        index: 20,
        slope_direction: BottomRight,
        slope_shape: {angle: Gentle, size: Thin}
      },
      {
        index: 19,
        slope_direction: BottomRight,
        slope_shape: {angle: Gentle, size: Thick}
      },
      {
        index: 24,
        slope_direction: BottomRight,
        slope_shape: {angle: Sharp, size: Thin}
      },
      {
        index: 22,
        slope_direction: BottomRight,
        slope_shape: {angle: Sharp, size: Thick}
      },
      {
        index: 12,
        custom_shape: {
          type: CIRCLE,
          radius: tile_width * 0.5,
          offset_x: tile_width * 0.5,
          offset_y: tile_height * 0.5
        }
      }
    ]);
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
