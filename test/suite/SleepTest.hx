package suite;

import suite.Test.*;
import echo.Body;
import echo.Echo;
import echo.World;
import echo.math.Vector2;

class SleepTest {
  public static function run() {
    test_falling_asleep();
    test_staying_put();
    test_waking();
    test_collisions();
    test_stacks();
  }
  /**
   * A World with a floor to drop Bodies onto.
   */
  static function world(sleeping:Bool = true, arcade:Bool = false):World {
    var w = Echo.start({width: 640, height: 360, gravity_y: 100, iterations: 5, arcade: arcade, sleeping_bodies: sleeping});
    w.add(new Body({mass: STATIC, x: 320, y: 340, material: {elasticity: 0}, shape: {type: RECT, width: 640, height: 20}}));
    w.listen();
    return w;
  }

  static function box(w:World, x:Float, y:Float, size:Float = 40):Body {
    var b = new Body({x: x, y: y, material: {elasticity: 0}, shape: {type: RECT, width: size, height: size}});
    w.add(b);
    return b;
  }

  static function step(w:World, frames:Int) for (i in 0...frames) w.step(1 / 60);

  static function test_falling_asleep() {
    section('sleep: falling asleep');
    var w = world();
    var b = box(w, 320, 100);
    step(w, 60);
    check('a falling Body stays awake', !b.sleeping && !b.resting, '${b.sleeping}');

    step(w, 180);
    check('a Body that lands falls asleep', b.sleeping, 'sleeping: ${b.sleeping}, resting: ${b.resting}, sleep_time: ${b.sleep_time}');
    check('a sleeping Body counts as resting', b.resting);
    check('falling asleep brings the Body to a stop', b.velocity.x == 0 && b.velocity.y == 0, '${b.velocity}');
    w.dispose();

    // Nothing sleeps unless the World asks for it
    w = world(false);
    b = box(w, 320, 100);
    step(w, 240);
    check('sleeping is opt-in', !b.sleeping && !b.resting);
    w.dispose();

    // ...and a Body can opt out on its own
    w = world();
    b = box(w, 320, 100);
    b.can_sleep = false;
    step(w, 240);
    check('can_sleep keeps a Body awake', !b.sleeping);
    check('a Body that opted out still reports that it has settled', b.resting);
    w.dispose();

    // A Body with a force on it is never at rest, even sitting on the floor
    w = world();
    b = box(w, 320, 100);
    step(w, 120);
    b.acceleration.set(0, 500);
    step(w, 240);
    check('a Body with acceleration on it never sleeps', !b.sleeping && !b.resting, '${b.sleeping}');
    b.acceleration.set(0, 0);
    b.torque = 50;
    step(w, 240);
    check('a Body with torque on it never sleeps', !b.sleeping, '${b.sleeping}');
    w.dispose();

    // A Body that never lands never settles
    w = Echo.start({width: 640, height: 100000, gravity_y: 100, sleeping_bodies: true});
    b = box(w, 320, 0);
    step(w, 600);
    check('a Body in free fall never sleeps', !b.sleeping && !b.resting, '${b.sleeping}');
    w.dispose();
  }

  static function test_staying_put() {
    section('sleep: staying put');
    var w = world();
    var b = box(w, 320, 100);
    step(w, 240);
    check('the Body is asleep to begin with', b.sleeping);

    var x = b.x;
    var y = b.y;
    step(w, 600);
    check('gravity does not build up on a sleeping Body', b.velocity.y == 0, '${b.velocity}');
    check('a sleeping Body does not drift', b.x == x && b.y == y, '${b.x}, ${b.y} vs $x, $y');
    check('a sleeping Body is immovable', b.is_immovable());
    check('a sleeping Body cannot move on its own', !b.can_move());
    w.dispose();
  }

  static function test_waking() {
    section('sleep: waking up');

    inline function sleeping_box(w:World):Body {
      var b = box(w, 320, 100);
      step(w, 240);
      return b;
    }

    var w = world();
    var b = sleeping_box(w);
    b.wake();
    check('wake() wakes the Body', !b.sleeping && b.sleep_time == 0);
    w.dispose();

    w = world();
    b = sleeping_box(w);
    b.set_position(200, 100);
    check('moving a sleeping Body wakes it', !b.sleeping);
    w.dispose();

    w = world();
    b = sleeping_box(w);
    b.rotation = 45;
    check('rotating a sleeping Body wakes it', !b.sleeping);
    w.dispose();

    w = world();
    b = sleeping_box(w);
    b.push(0, -200, false, VELOCITY);
    check('pushing a sleeping Body wakes it', !b.sleeping);
    check('the push is kept', b.velocity.y == -200, '${b.velocity}');
    w.dispose();

    // Setting velocity directly doesn't go through the Body at all, so the World has to notice it on the next step
    w = world();
    b = sleeping_box(w);
    var y_asleep = b.y;
    b.velocity.set(0, -200);
    check('setting velocity directly leaves the Body asleep until the next step', b.sleeping);
    step(w, 1);
    check('the next step wakes a Body whose velocity was set', !b.sleeping);
    check('the Body moves once awake', b.y < y_asleep, '${b.y} vs $y_asleep');
    w.dispose();

    // Something landing on a sleeping Body wakes it
    w = world();
    b = sleeping_box(w);
    var y = b.y;
    var dropped = box(w, 320, 100, 30);
    dropped.velocity.set(0, 300);
    step(w, 60);
    check('a Body landing on a sleeping one wakes it', !b.sleeping, '${b.sleeping}');
    check('the sleeping Body gets pushed by the impact', b.y != y, '${b.y} vs $y');
    w.dispose();

    // Taking away what a Body was resting on has to get it falling again
    w = world();
    b = sleeping_box(w);
    y = b.y;
    w.members[0].remove();
    check('removing the ground wakes the Bodies that were on it', !b.sleeping);
    step(w, 30);
    check('the woken Body falls', b.y > y, '${b.y} vs $y');
    w.dispose();

    w = world();
    b = sleeping_box(w);
    w.wake_bodies();
    check('wake_bodies() wakes every Body', !b.sleeping);
    step(w, 240);
    check('the Body settles again', b.sleeping);
    var bounds = b.bounds();
    bounds.set_from_min_max(bounds.min_x - 400, bounds.min_y, bounds.min_x - 300, bounds.max_y);
    w.wake_bodies(bounds);
    check('wake_bodies() leaves Bodies outside of the bounds alone', b.sleeping);
    bounds.put();
    bounds = b.bounds();
    w.wake_bodies(bounds);
    check('wake_bodies() wakes the Bodies inside the bounds', !b.sleeping);
    bounds.put();
    w.dispose();
  }

  static function test_collisions() {
    section('sleep: collisions');
    var w = world();
    var a = box(w, 260, 100);
    var b = box(w, 305, 100);
    step(w, 240);
    check('both Bodies are asleep', a.sleeping && b.sleeping, '${a.sleeping}, ${b.sleeping}');

    var pairs = 0;
    for (l in w.listeners) pairs += l.collisions.length;
    check('sleeping Bodies stop being collided against each other', pairs == 0, '$pairs');
    w.dispose();

    // A sleeping Body still holds up whatever lands on it
    w = world();
    a = box(w, 320, 100);
    step(w, 240);
    var a_y = a.y;
    b = box(w, 320, 0, 20);
    step(w, 240);
    check('a Body comes to rest on top of a sleeping one', approx(b.y, a.y - 30, 1), '${b.y} vs ${a.y}');
    check('the Body on top falls asleep too', b.sleeping);
    check('the sleeping Body underneath stays put', approx(a.y, a_y, 1), '${a.y} vs $a_y');
    w.dispose();
  }

  static function test_stacks() {
    section('sleep: stacks');

    for (arcade in [true, false]) {
      var label = arcade ? 'arcade' : 'full';
      var w = world(true, arcade);
      var boxes = [for (i in 0...5) box(w, 320, 320 - 30 - i * 31, 30)];
      step(w, 600);

      var asleep = 0;
      for (b in boxes) if (b.sleeping) asleep++;
      // A regression test for sleeping Bodies waking each other back up in a loop, which keeps a stack from settling
      check('$label: a settled stack falls asleep', asleep == boxes.length, '$asleep/${boxes.length} asleep');

      var pairs = 0;
      for (l in w.listeners) pairs += l.collisions.length;
      check('$label: a sleeping stack is not collided at all', pairs == 0, '$pairs');

      // Pulling the bottom Body out has to wake the whole stack, not just the Body that was touched
      boxes[0].set_position(100, 100);
      step(w, 60);
      var awake = 0;
      for (b in boxes) if (!b.sleeping) awake++;
      check('$label: waking one Body in a stack wakes the ones it was holding up', awake == boxes.length, '$awake/${boxes.length} awake');
      w.dispose();
    }
  }
}
