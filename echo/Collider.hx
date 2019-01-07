package echo;

import haxe.ds.Either;
import glib.Disposable;

typedef Collider = {
  var a:Either<Body, Group>;
  var b:Either<Body, Group>;
  var separate:Bool;
  var ?callback:Dynamic->Dynamic->Void;
}

class Colliders implements IDisposable {
  public var members:Array<Collider>;

  public function new() {
    members = [];
  }

  public function add(a:Either<Body, Group>, b:Either<Body, Group>, separate:Bool = false, ?callback:Dynamic->Dynamic->Void):Collider {
    var collider:Collider = {a: a, b: b, separate: separate};
    if (callback != null) collider.callback = callback;
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
}
