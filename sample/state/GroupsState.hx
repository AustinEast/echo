package state;

import echo.Body;
import echo.World;
import util.Random;

class GroupsState extends BaseState {
  var body_count:Int = 50;
  var circles:Array<Body>;
  var rects:Array<Body>;
  var floors:Array<Body>;
  var timer:Float;

  override public function enter(world:World) {
    Main.instance.state_text.text = "Sample: Grouped Collisions";
    timer = 0;
    // create some arrays to hold the different collision groups
    circles = [];
    rects = [];
    floors = [];

    // Add some platforms for the bodies to bounce off of
    // Setting the Mass to 0 makes them unmovable
    for (i in 0...4) {
      var floor = new Body({
        mass: STATIC,
        x: (world.width / 4) * i + (world.width / 8),
        y: world.height - 30,
        material: {elasticity: 0.3},
        shape: {
          type: RECT,
          width: world.width / 8,
          height: 10
        }
      });
      floors.push(floor);
      world.add(floor);
    }

    world.listen(circles, rects);
    world.listen(circles, floors);
    world.listen(rects, floors);
  }

  override function step(world:World, dt:Float) {
    timer += dt;
    if (timer > 0.3 + Random.range(-0.2, 0.2)) {
      if (circles.length < body_count) {
        var c = make_circle();
        circles.push(c);
        launch(world.add(c), world, true);
      }
      else {
        var found = false;
        for (member in circles) {
          if (!found && offscreen(member, world)) {
            launch(member, world, true);
            found = true;
          }
        }
      }

      if (rects.length < body_count) {
        var r = make_rect();
        rects.push(r);
        launch(world.add(r), world, false);
      }
      else {
        var found = false;
        for (member in rects) {
          if (!found && offscreen(member, world)) {
            launch(member, world, false);
            found = true;
          }
        }
      }

      timer = 0;
    }
  }

  inline function make_circle():Body return new Body({
    material: {elasticity: 0.5},
    shape: {
      type: CIRCLE,
      radius: Random.range(16, 32)
    }
  });

  inline function make_rect():Body return new Body({
    material: {elasticity: 0.5},
    shape: {
      type: RECT,
      width: Random.range(32, 64),
      height: Random.range(32, 64)
    }
  });

  inline function launch(b:Body, w:World, left:Bool) {
    b.set_position(left ? 20 : w.width - 20, w.height / 2);
    b.velocity.set(left ? 130 : -130, hxd.Math.lerp(-60, 20, Main.instance.scene.mouseY / w.height));
  }
}
