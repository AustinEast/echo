package echo.math;

import echo.math.Types.Vector3Type;

@:dox(hide)
@:noCompletion
class Vector3Default {
  public var x:Float;
  public var y:Float;
  public var z:Float;

  public inline function new(x:Float, y:Float, z:Float) {
    // the + 0.0 helps the optimizer realize it can collapse const float operations (from vector-math lib)
    this.x = x + 0.0;
    this.y = y + 0.0;
    this.z = z + 0.0;
  }

  public function toString():String
    return '{ x:$x, y:$y, z:$z }';
}

@:using(echo.math.Vector3)
@:forward(x, y, z)
abstract Vector3(Vector3Type) from Vector3Type to Vector3Type {
  @:from
  public static inline function from_arr(a:Array<Float>):Vector3
    return new Vector3(a[0], a[1], a[2]);

  @:to
  public inline function to_arr():Array<Float> {
    var self = this;
    return [self.x, self.y];
  }

  public inline function new(x:Float, y:Float, z:Float) @:privateAccess this = new Vector3Type(x, y, z);
}
