package echo.util;

/**
 * Generic Pooling container
 */
class Pool<T> implements IPool<T> {
  public var length(get, null):Int;

  var pool:Array<T>;
  var type:Class<T>;
  var count:Int;

  public function new(type:Class<T>) {
    this.type = type;
    pool = [];
    count = 0;
  }

  public function get():T {
    if (count == 0) return Type.createInstance(type, []);
    return pool[--count];
  }

  public function put(obj:T):Void {
    if (obj != null) {
      var i:Int = pool.indexOf(obj);
      // if the object's spot in the pool was overwritten, or if it's at or past count (in the inaccessible zone)
      if (i == -1 || i >= count) {
        pool[count++] = obj;
      }
    }
  }

  public function put_unsafe(obj:T):Void {
    if (obj != null) {
      pool[count++] = obj;
    }
  }

  public function pre_allocate(amount:Int):Void {
    while (amount-- > 0) pool[count++] = Type.createInstance(type, []);
  }

  public function clear():Array<T> {
    count = 0;
    var old_pool = pool;
    pool = [];
    return old_pool;
  }

  public function get_length() return count;
}

interface IPooled {
  function put():Void;
  private var pooled:Bool;
}

interface IPool<T> {
  function pre_allocate(amount:Int):Void;
  function clear():Array<T>;
}
