package echo.util;

@:forward
abstract LinearArray<T:{id:Int}>(LinearGroup<T>) from LinearGroup<T> to LinearGroup<T> {
  public inline function new() this = new LinearGroup();

  @:to
  public inline function to_array() {
    return @:privateAccess this.members;
  }

  @:arrayAccess
  inline function get_by_id(id:Int) return this.get(id);
}

@:generic
class LinearGroup<T:{id:Int}> {
  public var length(default, null):Int;

  var members:Array<T> = [];
  var free:Array<Int> = [];

  public function new() {}
  /**
   * Adds the item. This method expects that new items have an `id` set to `-1`.
   * @param item
   * @return T
   */
  public function add(item:T):T {
    // Dont re-add an item
    if (item.id > 0 && item.id < members.length && members[item.id] == item) {
      return item;
    }

    // Assign the item's id
    if (free.length > 0) {
      item.id = free.pop();
      members[item.id] = item;
    }
    else item.id = members.push(item) - 1;
    length++;

    return item;
  }

  public inline function get(id:Int):Null<T> {
    return this.members[id];
  }
  /**
   * Removes the item and sets it's `id` to `-1`.
   * @param item
   * @return Bool
   */
  public function remove(item:T):Bool {
    if (members[item.id] == item) {
      members[item.id] = null;
      free.push(item.id);
      item.id = -1;
      length--;
      return true;
    }
    return false;
  }

  public function clear() {
    for (item in iterator()) remove(item);
    members.resize(0);
  }

  public function filter(f:T->Bool) {
    var arr = [];
    for (item in iterator()) if (f(item)) arr.push(item);
    return arr;
  }

  public inline function iterator() {
    return new LinearGroupIterator<T>(members);
  }
}

class LinearGroupIterator<T> {
  var members:Array<T>;
  var cursor:Int;
  var length:Int;

  public inline function new(members:Array<T>) {
    this.members = members;
    this.cursor = 0;
    this.length = members.length;
  }

  public inline function next() {
    return hasNext() ? members[cursor++] : null;
  }

  public inline function hasNext():Bool {
    while (cursor < length && members[cursor] == null) {
      cursor++;
    }
    return cursor < length;
  }
}
