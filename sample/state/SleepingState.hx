package state;

import echo.Body;
import echo.Material;
import echo.World;
import util.Random;

class SleepingState extends BaseState {
  var body_count:Int = 90;
  var boxes:Array<Body>;
  var cursor:Body;

  override public function enter(world:World) {
    // Bodies that have come to rest are skipped by the simulation until something disturbs them again.
    // They are drawn in the Quadtree's color while they sleep - drag the ball through the pile to wake them back up
    world.sleeping_bodies = true;

    var material:Material = {elasticity: 0.2};
    boxes = [];

    for (i in 0...body_count) {
      boxes.push(world.add(new Body({
        x: Random.range(140, world.width - 140),
        y: Random.range(-400, world.height * 0.5),
        rotation: Random.range(0, 360),
        material: material,
        shape: Random.chance() ? {type: RECT, width: Random.range(14, 28), height: Random.range(14, 28)} : {type: CIRCLE, radius: Random.range(7, 13)}
      })));
    }

    // A pen for everything to pile up in
    world.add(new Body({mass: STATIC, x: world.width * 0.5, y: world.height - 10, material: material, shape: {type: RECT, width: world.width, height: 20}}));
    world.add(new Body({mass: STATIC, x: 110, y: world.height - 90, material: material, shape: {type: RECT, width: 20, height: 180}}));
    world.add(new Body({
      mass: STATIC,
      x: world.width - 110,
      y: world.height - 90,
      material: material,
      shape: {type: RECT, width: 20, height: 180}
    }));

    // A wrecking ball to stir the pile with. It is kinematic, so the pile can't push it around - and it never sleeps,
    // so that it keeps waking whatever it runs into
    cursor = new Body({
      x: world.width * 0.5,
      y: 60,
      kinematic: true,
      can_sleep: false,
      material: material,
      shape: {type: CIRCLE, radius: 22}
    });
    world.add(cursor);

    world.listen();
  }

  override function exit(world:World) {
    world.sleeping_bodies = false;
    super.exit(world);
  }

  override function step(world:World, dt:Float) {
    cursor.velocity.set((Main.instance.scene.mouseX - cursor.x) * 10, (Main.instance.scene.mouseY - cursor.y) * 10);

    var asleep = 0;
    for (b in boxes) if (b.sleeping) asleep++;
    Main.instance.state_text.text = 'Sample: Sleeping Bodies ($asleep of ${boxes.length} asleep - move the mouse to stir them)';

    // Reset any off-screen Bodies
    world.for_each((member) -> {
      if (member != cursor && offscreen(member, world)) {
        member.velocity.set(0, 0);
        member.set_position(Random.range(140, world.width - 140), 0);
      }
    });
  }
}
