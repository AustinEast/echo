package echo.util;

abstract BitMask(Int) {
  static inline function value(index:Int) return 1 << index;

  @:to public function to_int():Int return value(this);

  public function new() this = 0;

  public inline function remove(mask:Int):Int {
    return this = this & ~value(mask);
  }

  public inline function add(mask:Int):Int {
    return this = this | value(mask);
  }

  public inline function contains(mask:Int):Bool {
    return this & value(mask) != 0;
  }

  public inline function clear() {
    this = 0;
  }

  public inline function is_empty():Bool {
    return this == 0;
  }
}
