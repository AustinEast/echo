package echo.util;

import hxmath.math.Vector2;
import echo.shape.*;
import ghost.Log;

using hxmath.math.MathUtil;

class Debug {
  public var draw_bodies:Bool = true;
  public var draw_quadtree:Bool = true;
  public var shape_color:Int;
  public var shape_fill_color:Int;
  public var shape_collided_color:Int;
  public var quadtree_color:Int;
  public var quadtree_fill_color:Int;

  public static function log(world:World) {
    trace('World State:');
    for (member in world.members) {
      trace(' - Body #${member.id} { x: ${member.x} , y: ${member.y}, colliding: ${member.collided} }');
    }
  }

  public function draw(world:World, clear_canvas:Bool = true) {
    if (clear_canvas) clear();
    if (draw_quadtree) {
      draw_qd(world.static_quadtree);
      draw_qd(world.quadtree);
    }
    if (draw_bodies) for (body in world.members) {
      if (body.shapes.length != 0) {
        // var cos = Math.cos(body.rotation);
        // var sin = Math.sin(body.rotation);
        var v = new Vector2(0, 0);
        for (shape in body.shapes) {
          //body.rotation != 0 ? v.set(shape.x * cos - shape.y * sin, shape.y * cos + shape.x * sin) : 
          v.set(shape.x, shape.y);
          v.addWith(body.position);
          switch (shape.type) {
            case RECT:
              var r:Rect = cast shape;
              draw_rect(v.x - r.ex, v.y - r.ey, r.width, r.height, shape_fill_color, shape
                .collided ? shape_collided_color : shape_color, 0.2);
            case CIRCLE:
              var c:Circle = cast shape;

              draw_circle(v.x, v.y, c.radius, shape_fill_color, shape.collided ? shape_collided_color : shape_color, 0.2);
            case POLYGON:
          }
        }
      }
    }
  }

  public function draw_line(from_x:Float, from_y:Float, to_x:Float, to_y:Int, color:Int, alpha:Float = 1.) {}

  public function draw_rect(x:Float, y:Float, width:Float, height:Float, color:Int, ?stroke:Int, alpha:Float = 1.) {}

  public function draw_circle(x:Float, y:Float, radius:Float, color:Int, ?stroke:Int, alpha:Float = 1.) {}

  public function clear() {}

  function draw_qd(tree:QuadTree) for (child in tree.children) {
    draw_rect(child.left, child.top, child.width, child.height, quadtree_fill_color, quadtree_color, 0.2);
    draw_qd(child);
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
