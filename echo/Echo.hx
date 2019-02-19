package echo;

import echo.Body;
import echo.Collider;
import echo.Collisions;
import echo.World;

class Echo {
  public static function start(options:WorldOptions):World return new World(options);

  public static function listen(world:World, ?a:IEcho, ?b:IEcho, ?options:ColliderOptions):Collider {
    if (a == null) return b == null ? world.colliders.add(world, world, options) : world.colliders.add(b, b, options);
    if (b == null) return world.colliders.add(a, a, options);
    return world.colliders.add(a, b, options);
  }

  public static function step(world:World, dt:Float) {
    // Save WorldState to History
    var fdt = dt / world.iterations;
    for (i in 0...world.iterations) {
      Physics.step(world, fdt);
      Collisions.query(world);
      Physics.separate(world, fdt);
      // Notify New World and Collisions to Listeners
    }
  }

  public static function undo(world:World):World {
    return world;
  }

  public static function redo(world:World):World {
    return world;
  }

  public static function collide(a:IEcho, b:IEcho, ?options:ColliderOptions) {}
}

typedef WorldState = {
  var bodies:Array<Body>;
  var collisions:Array<Collision>;
}

interface IEcho {
  public var type(default, null):EchoType;
}

@:enum
abstract EchoType(Int) from Int to Int {
  var BODY = 0;
  var GROUP = 1;
}
