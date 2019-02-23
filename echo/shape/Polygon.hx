package echo.shape;

import hxmath.math.Vector2;
import echo.shape.*;

using hxmath.math.MathUtil;
/**
 * TODO: EVERYTHING
 */
class Polygon extends Shape {
  public var vertices:Array<Vector2>;
  @:isVar
  public var rotation(get, set):Float;

  public function new(x:Float = 0, y:Float = 0, ?vertices:Array<Vector2>, rotation:Float = 0) {
    super(x, y);
    this.vertices = vertices == null ? [] : vertices;
    this.rotation = rotation;
  }

  public inline function to_rect():Rect return Rect.get(x, y);

  public function from_rect() {}

  public function from_circle(sub_divisions:Int = 3) {}
}

typedef PolygonOptions = {
  var x:Float;
  var y:Float;
  var vertices:Array<Vector2>;
  var rotation:Float;
}
