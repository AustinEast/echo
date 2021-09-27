package state;

import util.Random;
import echo.util.verlet.Constraints;
import echo.util.verlet.Composite;
import echo.math.Vector2;
import echo.util.verlet.Verlet;
import echo.World;

using hxd.Math;

class VerletState extends BaseState {
  var verlet:Verlet;
  var grass:Array<Composite> = [];

  override function enter(parent:World) {
    super.enter(parent);
    Main.instance.state_text.text = "Sample: Softbody Verlet Physics";

    verlet = new Verlet({width: parent.width, height: parent.height, gravity_y: 20});

    // Create a couple random rectangles
    for (i in 0...4) {
      var box = Verlet.rect(Random.range(parent.width * 0.2, parent.width * 0.8), 80, 30, 40, 0.7);
      box.dots[0].x += Math.random() * 10;
      box.dots[0].y -= Math.random() * 20;
      verlet.composites.push(box);
    }

    var rope = Verlet.rope([for (i in 0...10) new Vector2(80 + i * 10, 70)], 0.7, [0]);
    verlet.composites.push(rope);

    // Create some grass
    var i = 0.;
    while (i < parent.width) {
      var g = new Composite();
      g.add_dot(i, parent.height);
      g.add_dot(i, parent.height - Random.range(4, 6));
      g.add_dot(i, parent.height - Random.range(11, 16));
      g.add_dot(i, parent.height - Random.range(19, 23));
      g.pin(0);
      g.pin(1);
      g.add_constraint(new DistanceConstraint(g.dots[0], g.dots[1], 0.97));
      g.add_constraint(new DistanceConstraint(g.dots[1], g.dots[2], 0.97));
      g.add_constraint(new DistanceConstraint(g.dots[2], g.dots[3], 0.97));
      g.add_constraint(new RotationConstraint(g.dots[0], g.dots[1], g.dots[2], 0.3));
      g.add_constraint(new RotationConstraint(g.dots[1], g.dots[2], g.dots[3], 0.1));
      verlet.composites.push(g);
      grass.push(g);
      i += Random.range(3, 7);
    }

    var cloth = Verlet.cloth(250, 0, 130, 130, 13, 6, .93);
    verlet.composites.push(cloth);
  }

  override function step(parent:World, dt:Float) {
    super.step(parent, dt);

    var w = Math.lerp(-1, 1, Main.instance.scene.mouseX / parent.width);
    if (w.isNaN()) w = 0;
    for (g in grass) g.dots[2].ax = Math.random() * 60 * w;
    if (Main.instance.playing) verlet.step(dt);
    Main.instance.debug.draw_verlet(verlet);
  }

  override function exit(world:World) {
    super.exit(world);
    verlet.dispose();
  }
}
