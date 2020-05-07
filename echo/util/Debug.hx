package echo.util;

import echo.data.Data;
import hxmath.math.Vector2;
import echo.shape.*;

using echo.util.Ext;
using hxmath.math.MathUtil;

class Debug {
  public var draw_bodies:Bool = true;
  public var draw_body_centers:Bool = false;
  public var draw_bounds:Bool = false;
  public var draw_shape_bounds:Bool = false;
  public var draw_quadtree:Bool = true;
  public var shape_outline_width:Float = 1;
  public var shape_fill_alpha:Float = 0;
  public var shape_color:Int;
  public var shape_fill_color:Int;
  public var shape_collided_color:Int;
  public var intersection_color:Int;
  public var intersection_overlap_color:Int;
  public var quadtree_color:Int;
  public var quadtree_fill_color:Int;

  public static function log(world:World) {
    trace('World State:');
    world.for_each(member -> trace(' - Body #${member.id} { x: ${member.x} , y: ${member.y}, colliding: ${member.collided} }'));
  }

  // Override Me!
  public function draw_line(from_x:Float, from_y:Float, to_x:Float, to_y:Float, color:Int, alpha:Float = 1) {}

  // Override Me!
  public function draw_rect(x:Float, y:Float, width:Float, height:Float, color:Int, ?stroke:Int, alpha:Float = 1) {}

  // Override Me!
  public function draw_circle(x:Float, y:Float, radius:Float, color:Int, ?stroke:Int, alpha:Float = 1) {}

  // Override Me!
  public function clear() {}

  public function draw(world:World, clear_canvas:Bool = true) {
    if (clear_canvas) clear();
    if (draw_quadtree) {
      draw_qd(world.static_quadtree);
      draw_qd(world.quadtree);
    }
    if (draw_bodies) world.for_each(member -> if (member.shapes.length != 0) {
      if (draw_body_centers) draw_rect(member.x - 1, member.y - 1, 1, 1, quadtree_color);
      for (shape in member.shapes) {
        var x = shape.x;
        var y = shape.y;
        switch (shape.type) {
          case RECT:
            var r:Rect = cast shape;
            if (r.transformed_rect != null && !r.rotation.equals(0)) {
              draw_polygon(r.transformed_rect.count, r.transformed_rect.vertices, shape_fill_color,
                r.transformed_rect.collided ? shape_collided_color : shape_color, shape_fill_alpha);
              if (draw_shape_bounds) {
                var b = r.transformed_rect.bounds();
                draw_rect(b.x - b.ex, b.y - b.ey, b.width, b.height, shape_fill_color, r.transformed_rect.collided ? shape_collided_color : shape_color, 0);
                b.put();
              }
            }
            else draw_rect(x - r.ex, y - r.ey, r.width, r.height, shape_fill_color, shape.collided ? shape_collided_color : shape_color, 0);
          case CIRCLE:
            var c:Circle = cast shape;

            draw_circle(x, y, c.radius, shape_fill_color, shape.collided ? shape_collided_color : shape_color, shape_fill_alpha);
            if (draw_shape_bounds) {
              var b = c.bounds();
              draw_rect(b.x - b.ex, b.y - b.ey, b.width, b.height, shape_fill_color, shape.collided ? shape_collided_color : shape_color, 0);
              b.put();
            }
          case POLYGON:
            var p:Polygon = cast shape;

            draw_polygon(p.count, p.vertices, shape_fill_color, shape.collided ? shape_collided_color : shape_color, shape_fill_alpha);
            if (draw_shape_bounds) {
              var b = p.bounds();
              draw_rect(b.x - b.ex, b.y - b.ey, b.width, b.height, shape_fill_color, shape.collided ? shape_collided_color : shape_color, 0);
              b.put();
            }
        }
      }
      if (draw_bounds) {
        var b = member.bounds();
        draw_rect(b.x - b.ex, b.y - b.ey, b.width, b.height, shape_fill_color, shape_color, 0);
        b.put();
      }
    });
  }

  public function draw_intersection(intersection:Intersection, draw_overlap:Bool = true, draw_normal:Bool = true) {
    if (intersection == null) return;
    var closest = intersection.closest;
    if (closest == null) return;

    draw_line(closest.line.start.x, closest.line.start.y, closest.hit.x, closest.hit.y, intersection_color);
    if (draw_overlap) draw_line(closest.hit.x, closest.hit.y, closest.line.end.x, closest.line.end.y, intersection_overlap_color);
    if (draw_normal) {
      var normal = Line.get_from_vector(closest.hit, closest.normal.angle.radToDeg(), 10);
      draw_line(normal.x, normal.y, normal.dx, normal.dy, intersection_overlap_color);
      normal.put();
    }
  }

  public function draw_polygon(count:Int, vertices:Array<Vector2>, color:Int, ?stroke:Int, alpha:Float = 1) {
    if (count < 2) return;
    for (i in 1...count) draw_line(vertices[i - 1].x, vertices[i - 1].y, vertices[i].x, vertices[i].y, stroke, 1);
    var vl = count - 1;
    draw_line(vertices[vl].x, vertices[vl].y, vertices[0].x, vertices[0].y, stroke, 1);
  }

  function draw_qd(tree:QuadTree) for (child in tree.children) {
    draw_rect(child.left, child.top, child.width, child.height, quadtree_fill_color, quadtree_color, 0.1);
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
    intersection_color = 0x00cbdbfc;
    intersection_overlap_color = 0x00d95763;

    canvas = new h2d.Graphics(parent);
  }

  override public inline function draw_line(from_x:Float, from_y:Float, to_x:Float, to_y:Float, color:Int, alpha:Float = 1.) {
    canvas.lineStyle(shape_outline_width, color, alpha);
    canvas.moveTo(from_x, from_y);
    canvas.lineTo(to_x, to_y);
  }

  override public inline function draw_rect(x:Float, y:Float, width:Float, height:Float, color:Int, ?stroke:Int, alpha:Float = 1.) {
    canvas.beginFill(color, alpha);
    stroke != null ? canvas.lineStyle(shape_outline_width, stroke, 1) : canvas.lineStyle();
    canvas.drawRect(x, y, width, height);
    canvas.endFill();
  }

  override public inline function draw_circle(x:Float, y:Float, radius:Float, color:Int, ?stroke:Int, alpha:Float = 1.) {
    canvas.beginFill(color, alpha);
    stroke != null ? canvas.lineStyle(shape_outline_width, stroke, 1) : canvas.lineStyle();
    canvas.drawCircle(x, y, radius);
    canvas.endFill();
  }

  override public function draw_polygon(count:Int, vertices:Array<Vector2>, color:Int, ?stroke:Int, alpha:Float = 1) {
    if (count < 2) return;
    canvas.beginFill(color, alpha);
    stroke != null ? canvas.lineStyle(shape_outline_width, stroke, 1) : canvas.lineStyle();
    canvas.moveTo(vertices[count - 1].x, vertices[count - 1].y);
    for (i in 0...count) canvas.lineTo(vertices[i].x, vertices[i].y);
  }

  override public inline function clear() canvas.clear();
}
#end

#if openfl
class OpenFLDebug extends Debug {
  public var canvas:openfl.display.Sprite;

  public function new() {
    shape_color = 0x005b6ee1;
    shape_fill_color = 0x00cbdbfc;
    shape_collided_color = 0x00d95763;
    quadtree_color = 0x00847e87;
    quadtree_fill_color = 0x009badb7;
    intersection_color = 0x00cbdbfc;
    intersection_overlap_color = 0x00d95763;

    canvas = new openfl.display.Sprite();
  }

  public function get_sprite() return canvas;

  override public inline function draw_line(from_x:Float, from_y:Float, to_x:Float, to_y:Float, color:Int, alpha:Float = 1.) {
    canvas.graphics.lineStyle(1, color, alpha);
    canvas.graphics.moveTo(from_x, from_y);
    canvas.graphics.lineTo(to_x, to_y);
  }

  override public inline function draw_rect(x:Float, y:Float, width:Float, height:Float, color:Int, ?stroke:Int, alpha:Float = 1.) {
    canvas.graphics.beginFill(color, alpha);
    stroke != null ? canvas.graphics.lineStyle(1, stroke, 1) : canvas.graphics.lineStyle();
    canvas.graphics.drawRect(x, y, width, height);
    canvas.graphics.endFill();
  }

  override public inline function draw_circle(x:Float, y:Float, radius:Float, color:Int, ?stroke:Int, alpha:Float = 1.) {
    canvas.graphics.beginFill(color, alpha);
    stroke != null ? canvas.graphics.lineStyle(1, stroke, 1) : canvas.graphics.lineStyle();
    canvas.graphics.drawCircle(x, y, radius);
    canvas.graphics.endFill();
  }

  override public inline function clear() canvas.graphics.clear();
}
#end
