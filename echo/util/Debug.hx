package echo.util;

import echo.shape.*;

class Debug {
  public var shape_color:Int;
  public var shape_fill_color:Int;
  public var shape_collided_color:Int;
  public var quadtree_color:Int;
  public var quadtree_fill_color:Int;

  public function draw_line(from_x:Float, from_y:Float, to_x:Float, to_y:Int, color:Int, alpha:Float = 1.) {}

  public function draw_rect(x:Float, y:Float, width:Float, height:Float, color:Int, ?stroke:Int, alpha:Float = 1.) {}

  public function draw_circle(x:Float, y:Float, radius:Float, color:Int, ?stroke:Int, alpha:Float = 1.) {}

  public function clear() {}

  public function draw(state:State) {
    clear();
    for (tree in state.quadtrees) draw_quadtree(tree);
    for (body in state.members) {
      if (body.shape != null) {
        switch (body.shape.type) {
          case RECT:
            var r:Rect = cast body.shape;
            draw_rect(r.x + body.x, r.y + body.y, r.width, r.height, shape_fill_color, shape_color, 0.2);
          case CIRCLE:
            var c:Circle = cast body.shape;
            draw_circle(c.x + body.x, c.y + body.y, c.radius, shape_fill_color, shape_color, 0.2);
          case POLYGON:
        }
      }
    }
  }

  function draw_quadtree(tree:QuadTree) for (child in tree.children) {
    draw_rect(child.left + child.x, child.top + child.y, child.width, child.height, quadtree_fill_color, quadtree_color, 0.4);
    draw_quadtree(child);
  }
}

#if heaps
class HeapsDebug extends Debug {
  public var canvas:h2d.Graphics;

  public function new(?parent:h2d.Object) {
    shape_color = 0x005b6ee1;
    shape_fill_color = 0x00cbdbfc;
    shape_collided_color = 0x00d95763;
    quadtree_color = 0x00847e87;
    quadtree_fill_color = 0x009badb7;

    canvas = new h2d.Graphics(parent);
  }

  override public inline function draw_line(from_x:Float, from_y:Float, to_x:Float, to_y:Int, color:Int, alpha:Float = 1.) {
    canvas.lineStyle(1, color, alpha);
    canvas.moveTo(from_x, from_y);
    canvas.lineTo(to_x, to_y);
  }

  override public inline function draw_rect(x:Float, y:Float, width:Float, height:Float, color:Int, ?stroke:Int, alpha:Float = 1.) {
    canvas.beginFill(color, alpha);
    stroke != null ? canvas.lineStyle(1, stroke, 1) : canvas.lineStyle();
    canvas.drawRect(x, y, width, height);
    canvas.endFill();
  }

  override public inline function draw_circle(x:Float, y:Float, radius:Float, color:Int, ?stroke:Int, alpha:Float = 1.) {
    canvas.beginFill(color, alpha);
    stroke != null ? canvas.lineStyle(1, stroke, 1) : canvas.lineStyle();
    canvas.drawCircle(x, y, radius);
    canvas.endFill();
  }

  override public inline function clear() canvas.clear();
}
#end
