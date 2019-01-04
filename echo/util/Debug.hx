package echo.util;

import h3d.scene.World;

class Debug {
  public var shape_color:Int;
  public var shape_fill_color:Int;
  public var shape_collided_color:Int;
  public var quadtree_color:Int;
  public var quadtree_fill_color:Int;

  public function draw_line(from_x:Float, from_y:Float, to_x:Float, to_y:Int, color:Int) {}

  public function draw_rect(x:Float, y:Float, width:Float, height:Float, stroke:Int, ?fill:Int) {}

  public function draw_circle(x:Float, y:Float, radius:Float, stroke:Int, ?fill:Int) {}

  public function draw(world:World) {}
}
