package echo;

import ghost.Disposable;
import echo.Echo;
import echo.data.Types;
/**
 * Container for storing a collection of Bodies. Use these to group Bodies for a `Listener`
 */
typedef Group = TypedGroup<Body>;
/**
 * Typed container for storing a collection of Bodies. Use these to group Bodies for a `Listener`
 */
@:generic
class TypedGroup<T:Body> implements IEcho implements IDisposable {
  public var count(get, null):Int;
  public var echo_type(default, null):EchoType;

  var members:Array<Body>;

  public function new(?members:Array<Body>) {
    this.members = members == null ? [] : members;
    echo_type = GROUP;
  }

  public function add(body:Body):Body {
    members.remove(body);
    members.push(body);
    return body;
  }

  public function remove(body:Body):Body {
    members.remove(body);
    return body;
  }

  public inline function dynamics():Array<Body> return members.filter(b -> return b.mass > 0);

  public inline function statics():Array<Body> return members.filter(b -> return b.mass == 0);

  public inline function for_each(f:Body->Void) for (b in members) f(b);

  public inline function for_each_dynamic(f:Body->Void) for (b in members) if (b.mass > 0) f(b);

  public inline function for_each_static(f:Body->Void) for (b in members) if (b.mass == 0) f(b);

  public function clear() members = [];

  public function dispose() members = null;

  inline function get_count():Int return members.length;
}
