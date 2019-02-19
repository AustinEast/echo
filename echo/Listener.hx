package echo;

import glib.Disposable;
import echo.Echo;
import echo.Collisions;
/**
 * Data Structure used to listen for Collisions between Bodies and Groups of Bodies
 */
typedef Listener = {
  var a:IEcho;
  var b:IEcho;
  var separate:Bool;
  var collisions:Array<Collision>;
  var last_collisions:Array<Collision>;
  var ?callback:Dynamic->Dynamic->Collision->Void;
  var ?condition:Dynamic->Dynamic->Collision->Bool;
}
/**
 * Container used to store Listeners
 */
class Listeners implements IDisposable {
  public static var listener_defaults(get, null):ListenerOptions;

  public var members:Array<Listener>;
  public var world:World;

  public function new(world:World, ?members:Array<Listener>) {
    this.world = world;
    this.members = members == null ? [] : members;
  }
  /**
   * Add a new Listener to listen for collisions
   * @param a The first `Body` or `Group` to collide against
   * @param b The second `Body` or `Group` to collide against
   * @param options Options to define the Listener's behavior
   * @return Listener
   */
  public function add(a:IEcho, b:IEcho, ?options:ListenerOptions):Listener {
    options = glib.Data.copy_fields(options, listener_defaults);
    var listener:Listener = {
      a: a,
      b: b,
      separate: options.separate,
      collisions: [],
      last_collisions: []
    };
    if (options.callback != null) listener.callback = options.callback;
    if (options.condition != null) listener.condition = options.condition;
    members.push(listener);
    return listener;
  }
  /**
   * Removes a Listener from the Container
   * @param listener Listener to remove
   * @return Listener
   */
  public function remove(listener:Listener):Listener {
    members.remove(listener);
    return listener;
  }

  public function clear() {
    members = [];
  }

  public function dispose() {
    members = null;
  }

  static function get_listener_defaults():ListenerOptions return {
    separate: true
  }
}

typedef ListenerOptions = {
  var ?separate:Bool;
  var ?callback:Dynamic->Dynamic->Collision->Void;
  var ?condition:Dynamic->Dynamic->Collision->Bool;
}
