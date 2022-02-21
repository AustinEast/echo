package echo.util;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.TypeTools;
using haxe.macro.ComplexTypeTools;
using Lambda;
#end
/**
 *	Implementing this interface on a Class will run `PoolableMacros.build`, then remove itself.
**/
@:autoBuild(echo.util.PoolableMacros.build())
interface Poolable {
  function put():Void;
}

@:deprecated('`IPooled` renamed to `IPoolable.')
typedef IPooled = Poolable;

interface Pool<T> {
  function pre_allocate(amount:Int):Void;
  function clear():Array<T>;
}
/**
 * Generic Pooling container
 */
@:generic
class GenericPool<T> implements Pool<T> {
  public var length(get, null):Int;

  var members:Array<T>;
  var type:Class<T>;
  var count:Int;

  public function new(type:Class<T>) {
    this.type = type;
    members = [];
    count = 0;
  }

  public function get():T {
    if (count == 0) return Type.createInstance(type, []);
    return members[--count];
  }

  public function put(obj:T):Void {
    if (obj != null) {
      var i:Int = members.indexOf(obj);
      // if the object's spot in the pool was overwritten, or if it's at or past count (in the inaccessible zone)
      if (i == -1 || i >= count) {
        members[count++] = obj;
      }
    }
  }

  public function put_unsafe(obj:T):Void {
    if (obj != null) {
      members[count++] = obj;
    }
  }

  public function pre_allocate(amount:Int):Void {
    while (amount-- > 0) members[count++] = Type.createInstance(type, []);
  }

  public function clear():Array<T> {
    count = 0;
    var old_pool = members;
    members = [];
    return old_pool;
  }

  public function get_length() return count;
}

class PoolableMacros {
  #if macro
  public static function build():Array<Field> {
    var pos = Context.currentPos();
    var t = Context.getLocalType();
    var ct = Context.toComplexType(t);
    var cl = t.getClass();

    var append:Array<Field> = [
      {
        name: 'pool',
        kind: FVar(macro:echo.util.Poolable.GenericPool<$ct>, macro new echo.util.Poolable.GenericPool<$ct>($p{cl.pack.concat([cl.name])})),
        pos: pos,
        access: [AStatic, APrivate]
      },
      {
        name: 'get_pool',
        kind: FFun({
          args: [],
          expr: macro return pool,
          ret: macro:echo.util.Poolable.Pool<$ct>
        }),
        pos: pos,
        access: [AStatic, APublic]
      }
    ];

    // Only add this on Classes that directly implemented `Poolable` (and not any children of those classes)
    if (Context.getLocalClass().get().interfaces.exists(i -> i.t.get().name == 'Poolable')) append.push({
      name: 'pooled',
      kind: FProp('default', 'null', macro:Bool, macro false),
      pos: pos,
      access: [APublic]
    });

    return Context.getBuildFields().concat(append);
  }
  #end
}
