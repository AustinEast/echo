package state;

import echo.Line;
import echo.Body;
import echo.World;
import ghost.Random;

class LinecastState extends BaseState {
  var body_count:Int = 30;
  var dynamics:Array<Body> = [];
  var line:Line;

  override public function enter(world:World) {
    Main.instance.state_text.text = "Sample: Linecasting";
    // Add a bunch of random Physics Bodies to the World
    for (i in 0...body_count) {
      var b = new Body({
        x: (world.width * 0.35) * Math.cos(i) + world.width * 0.5,
        y: (world.height * 0.35) * Math.sin(i) + world.height * 0.5,
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

    line = Line.get(world.width / 2, world.height / 2, world.width / 2, world.height / 2);
  }

  override function step(world:World, dt:Float) {
    line.end.set(Main.instance.scene.mouseX, Main.instance.scene.mouseY);
    var result = line.linecast(dynamics);
    if (result != null) Main.instance.debug.draw_intersection(result);
    else Main.instance.debug.draw_line(line.start.x, line.start.y, line.end.x, line.end.y, Main.instance.debug.intersection_color);
  }
}
