package state;

import echo.Echo;
import hxmath.math.Vector2;
import echo.Line;
import echo.Body;
import echo.World;
import util.Random;

class Linecast2State extends BaseState {
  var body_count:Int = 50;
  var cast_count:Int = 100;
  var cast_length:Float = 90;
  var dynamics:Array<Body> = [];

  override public function enter(world:World) {
    Main.instance.state_text.text = "Sample: Linecasting 2";
    // Add a bunch of random Physics Bodies to the World
    for (i in 0...body_count) {
      var b = new Body({
        x: Random.range(0, world.width),
        y: Random.range(0, world.height),
        rotational_velocity: Random.range(-20, 20),
        gravity_scale: 0,
        shape: {
          type: Random.chance() ? POLYGON : CIRCLE,
          radius: Random.range(16, 32),
          width: Random.range(16, 48),
          height: Random.range(16, 48),
          sides: Random.range_int(3, 8)
        }
      });
      dynamics.push(b);
      world.add(b);
    }

    // world.listen();
  }

  override function step(world:World, dt:Float) {
    var mouse = new Vector2(Main.instance.scene.mouseX, Main.instance.scene.mouseY);
    var line = Line.get();
    for (i in 0...cast_count) {
      line.set_from_vector(mouse, 360 * (i / cast_count), cast_length);
      var result = line.linecast(dynamics);
      if (result != null) Main.instance.debug.draw_intersection(result, false);
      else Main.instance.debug.draw_line(line.start.x, line.start.y, line.end.x, line.end.y, Main.instance.debug.intersection_color);
    }
    line.put();
  }
}
