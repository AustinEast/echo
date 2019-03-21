package echo.shape;

import hxmath.math.Vector2;
import echo.shape.*;

using hxmath.math.MathUtil;
/**
 * TODO: EVERYTHING
 */
class Polygon extends Shape {
  public var vertices:Array<Vector2>;

  public function new(x:Float = 0, y:Float = 0, ?vertices:Array<Vector2>) {
    super(x, y);
    this.vertices = vertices == null ? [] : vertices;
  }

  public inline function to_rect():Rect return Rect.get(x, y);

  public function from_rect() {}

  public function from_circle(sub_divisions:Int = 3) {}
}
