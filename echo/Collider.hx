package echo;

import glib.Disposable;
import echo.Echo;
import echo.Collisions;

typedef Collider = {
  var a:IEcho;
  var b:IEcho;
  var separate:Bool;
  var collisions:Array<Collision>;
  var last_collisions:Array<Collision>;
  var ?callback:Dynamic->Dynamic->Collision->Void;
  var ?condition:Dynamic->Dynamic->Collision->Bool;
}

class Colliders implements IDisposable {
  public static var collider_defaults(get, null):ColliderOptions;

  public var members:Array<Collider>;
  public var world:World;

  public function new(world:World, ?members:Array<Collider>) {
    this.world = world;
    this.members = members == null ? [] : members;
  }

  public function add(a:IEcho, b:IEcho, ?options:ColliderOptions):Collider {
    options = glib.Data.copy_fields(options, collider_defaults);
    var collider:Collider = {
      a: a,
      b: b,
      separate: options.separate,
      collisions: [],
      last_collisions: []
    };
    if (options.callback != null) collider.callback = options.callback;
    if (options.condition != null) collider.condition = options.condition;
    members.push(collider);
    return collider;
  }

  public function remove(collider:Collider):Collider {
    members.remove(collider);
    return collider;
  }

  public function dispose() {
    members = null;
  }

  static function get_collider_defaults():ColliderOptions return {
    separate: true
  }
}

typedef ColliderOptions = {
  var ?separate:Bool;
  var ?callback:Dynamic->Dynamic->Collision->Void;
  var ?condition:Dynamic->Dynamic->Collision->Bool;
}
