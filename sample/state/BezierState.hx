package state;

import hxmath.math.MathUtil;
import echo.data.Data.IntersectionData;
import echo.util.SAT;
import echo.Line;
import h2d.Interactive;
import hxd.Key;
import echo.util.Bezier;
import echo.World;
import hxmath.math.Vector2;

class BezierState extends BaseState {
  final segments = 100;

  var mode = [Cubic, Quadratic, Linear];
  var current_mode = 0;
  var controls:Array<Interactive> = [];
  var bezier:Bezier;
  var line:Line;
  var t:Float = 0;
  var qt:Float = 0;

  override function enter(parent:World) {
    super.enter(parent);

    var c = parent.center();

    // Create a new Bezier Curve with some control points
    bezier = new Bezier([
      new Vector2(c.x - 170, c.y + 80),
      new Vector2(c.x - 40, c.y + 80),
      new Vector2(c.x + 40, c.y - 80),
      new Vector2(c.x + 170, c.y - 80),
      // new Vector2(c.x - 170, c.y + 100),
      // new Vector2(c.x - 40, c.y + 100),
      // new Vector2(c.x + 40, c.y - 100),
      // new Vector2(c.x + 170, c.y - 100)
    ]);

    // For each control point in the Bezier Curve, create an h2d.Interactive so we can move the control points around
    for (i in 0...bezier.control_count) {
      var p = bezier.get_control_point(i);
      var interactive = new Interactive(6, 6, Main.instance.scene);
      interactive.setPosition(p.x - interactive.width * 0.5, p.y - interactive.height * 0.5);
      interactive.isEllipse = true;
      interactive.onPush = (e) -> {
        interactive.startDrag((e) -> {
          var x = Main.instance.scene.mouseX;
          var y = Main.instance.scene.mouseY;
          interactive.x = x - interactive.width * 0.5;
          interactive.y = y - interactive.height * 0.5;
          bezier.set_control_point(i, x, y);
        });
      };
      interactive.onRelease = (e) -> {
        interactive.stopDrag();
      };
    }

    // Create a line to linecast again the Bezier Curve
    line = Line.get(c.x, c.y - 120, c.x, c.y + 120);
    c.put();
  }

  override function step(parent:World, dt:Float) {
    super.step(parent, dt);

    t += dt;
    qt += dt * 0.25;

    if (Key.isPressed(Key.SPACE)) {
      current_mode++;
      if (current_mode >= mode.length) current_mode = 0;
      bezier.curve_mode = mode[current_mode];
    }

    // Draw the Bezier Curve
    Main.instance.debug.draw_bezier(bezier);

    // Move the linecasting Line
    var c = parent.center();
    line.dx = line.x = c.x + Math.sin(t) * 160;
    c.put();

    // Perform a linecast against the Bezier Curve
    var closest:IntersectionData = null;
    for (l in bezier.lines) {
      var result = SAT.line_intersects_line(line, l);
      if (closest == null || result != null && result.distance < closest.distance) closest = result;
    }

    // Draw the linecast results
    if (closest != null) Main.instance.debug.draw_intersection_data(closest);
    else Main.instance.debug.draw_line(line.start.x, line.start.y, line.end.x, line.end.y, Main.instance.debug.intersection_overlap_color);

    // Draw a point along the Bezier Curve
    var p = bezier.get_point(0.5 * (1 + Math.sin(2 * Math.PI * qt)));
    if (p != null) Main.instance.debug.draw_circle(p.x, p.y, 5, Main.instance.debug.shape_color);
  }
}
