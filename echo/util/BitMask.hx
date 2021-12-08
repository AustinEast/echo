package echo.util;

abstract BitMask(Int) to Int {
  
  @:from
  public static function from_int(i:Int):BitMask {
    return new BitMask(1 << i);
  }

  public function new(value:Int = 0) this = value;

  public inline function remove(mask:BitMask):Int {
    return this = this & ~mask;
  }

  public inline function add(mask:BitMask):Int {
    return this = this | mask;
  }

  public inline function contains(mask:BitMask):Bool {
    return this & mask != 0;
  }

  public inline function clear() {
    this = 0;
  }

  public inline function is_empty():Bool {
    return this == 0;
  }
}
