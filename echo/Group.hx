package echo;

import ghost.Disposable;
import echo.Echo;
import echo.data.Types;
/**
 * Container for storing a collection of Bodies. Use these to group Bodies for a `Listener`. Alias for `TypedGroup<Body>`
 */
typedef Group = TypedGroup<Body>;
/**
 * Typed container for storing a collection of Bodies. Use these to group Bodies for a `Listener`.
 */
class TypedGroup<T:Body> implements IDisposable {
  public var members:Array<T>;
  public var count(get, null):Int;

  public function new(?members:Array<T>) {
    this.members = members == null ? [] : members;
  }

  public function add(body:T):T {
    members.remove(body);
    members.push(body);
    return body;
  }

  public function remove(body:T):T {
    members.remove(body);
    return body;
  }

  public inline function dynamics():Array<T> return members.filter(b -> return b.mass > 0);

  public inline function statics():Array<T> return members.filter(b -> return b.mass == 0);

  public function iterator() return members.iterator();

  public inline function for_each(f:T->Void, recursive:Bool = true) for (b in members) f(cast b);

  public inline function for_each_dynamic(f:T->Void, recursive:Bool = true) for (b in members) if (b.mass > 0) f(cast b);

  public inline function for_each_static(f:T->Void, recursive:Bool = true) for (b in members) if (b.mass == 0) f(cast b);

  public function clear() members.resize(0);

  public function dispose() members = null;

  inline function get_count():Int return members.length;
}