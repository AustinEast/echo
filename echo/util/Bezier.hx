package echo.util;

import echo.util.Disposable;
import hxmath.math.Vector2;

using hxmath.math.MathUtil;
using Math;

class Bezier implements IDisposable {
  /**
   * Gets the point at the defined `t` (a value between 0.0 to 1.0) from a Quadratic Bezier Curve constructed out of points (ax, ay), (bx, by), and (cx, cy).
   */
  public static function point_on_quadratic_curve(t:Float, ax:Float, ay:Float, bx:Float, by:Float, cx:Float, cy:Float):Vector2 {
    // clamp the input
    t = t.clamp(0, 1);

    if (t == 0) return new Vector2(ax, ay);
    if (t == 1) return new Vector2(cx, cy);

    // negated t
    final u = 1 - t;
    // components
    final tu = t * u;
    final tt = t * t;
    final uu = u * u;

    inline function pos(a:Float, b:Float, c:Float) return a * uu + b * 2 * tu + c * tt;

    return new Vector2(pos(ax, bx, cx), pos(ay, by, cy));
  }
  /**
   * Gets the point at the defined `t` (a value between 0.0 to 1.0) from a Cubic Bezier Curve constructed out of points (ax, ay), (bx, by), (cx, cy), and (dx, dy).
   */
  public static function point_on_cubic_curve(t:Float, ax:Float, ay:Float, bx:Float, by:Float, cx:Float, cy:Float, dx:Float, dy:Float):Vector2 {
    // clamp the input
    t = t.clamp(0, 1);

    if (t == 0) return new Vector2(ax, ay);
    if (t == 1) return new Vector2(dx, dy);

    // negated t
    final u = 1 - t;
    // components
    final tt = t * t;
    final ttt = tt * t;
    final uu = u * u;
    final uuu = uu * u;

    inline function pos(a:Float, b:Float, c:Float, d:Float) return a * uuu + b * 3 * uu * t + c * 3 * tt * u + d * ttt;

    return new Vector2(pos(ax, bx, cx, dx), pos(ay, by, cy, dy));
  }
  /**
   * Cached Array of Lines that represents the current state of the Curve.
   */
  public var lines(get, null):Array<Line> = [];
  /**
   * The method used to construct `lines` from the Curve.
   */
  public var line_mode(default, set):BezierLineMode = Segments(50);
  /**
   * The amount of control points in this Curve.
   */
  public var control_count(get, never):Int;

  public var curve_mode(default, set):BezierCurve;

  public var curve_count(default, null):Int = 0;

  var control_points:Array<Vector2>;

  var dirty:Bool = true;

  public function new(?control_points:Array<Vector2>, curve_mode:BezierCurve = Cubic) {
    this.control_points = control_points != null ? control_points : [];
    this.curve_mode = curve_mode;
    update_curve_count();
  }

  public function dispose() {
    control_points = null;
    lines = null;
  }

  public function add_control_point(x:Float, y:Float) {
    control_points.push(new Vector2(x, y));
    update_curve_count();
    dirty = true;
  }

  public function get_control_point(index:Int):Null<Vector2> {
    if (index >= control_points.length || index < 0) return null;
    return control_points[index].clone();
  }

  public function set_control_point(index:Int, x:Float, y:Float) {
    if (index < 0) return;
    if (index >= control_points.length) {
      while (index >= control_points.length) control_points.push(new Vector2(0, 0));
      update_curve_count();
    }
    control_points[index].set(x, y);
    dirty = true;
  }

  public inline function remove_control_point(index:Int) {
    control_points.splice(index, 1);
    update_curve_count();
    dirty = true;
  }

  public inline function remove_all_control_points() {
    control_points.resize(0);
    update_curve_count();
    dirty = true;
  }
  /**
   * Gets the point on the Curve at the defined `t`.
   * @param t A value between 0.0 to 1.0.
   * @param start_index Determines the starting control point that will be used to construct the Curve. If set to -1, this will be determined automatically based on `t`.
   */
  public function get_point(t:Float, start_index:Int = -1):Null<Vector2> {
    // if there arent enough control points to construct a curve, return null
    if (curve_count < 1) return null;
    // if the start index is -1, determine which curve should be constructed based on `t`
    if (start_index < 0) {
      var ratio = curve_count * t;
      start_index = Math.floor(ratio) * curve_mode;
      t = ratio % 1;
    }

    // if the start index + it's needed control points exceed the total control points, return null
    if (start_index + curve_mode >= control_points.length) return null;
    return switch curve_mode {
      case Linear:
        var l = Line.get(control_points[start_index].x, control_points[start_index].y, control_points[start_index + 1].x, control_points[start_index + 1].y);
        var p = l.point_along_ratio(t);
        l.put();
        return p;
      case Quadratic:
        point_on_quadratic_curve(t, control_points[start_index].x, control_points[start_index].y, control_points[start_index + 1].x,
          control_points[start_index + 1].y, control_points[start_index + 2].x, control_points[start_index + 2].y);
      case Cubic:
        point_on_cubic_curve(t, control_points[start_index].x, control_points[start_index].y, control_points[start_index + 1].x,
          control_points[start_index + 1].y, control_points[start_index + 2].x, control_points[start_index + 2].y, control_points[start_index + 3].x,
          control_points[start_index + 3].y);
    };
  }

  function get_lines():Array<Line> {
    if (dirty) {
      dirty = false;
      while (lines.length > 0) lines.pop().put();
      // optimized for Linear Curves
      if (curve_mode == Linear) for (j in 0...curve_count) {
        var i = j * curve_mode;
        if (i >= control_points.length - 1) break;
        lines.push(Line.get(control_points[i].x, control_points[i].y, control_points[i + 1].x, control_points[i + 1].y));
      }
      else switch line_mode {
        case Segments(amount):
          var step = 1 / amount;
          for (j in 0...curve_count) {
            var start_index = j * curve_mode;
            var lp:Vector2 = get_point(0, start_index);
            for (i in 1...amount - 1) {
              var t = i * step;
              var p = get_point(t, start_index);
              if (lp != null && p != null) {
                lines.push(Line.get(lp.x, lp.y, p.x, p.y));
              }
              lp = p;
            }
            var p = get_point(1, start_index);
            if (lp != null && p != null) {
              lines.push(Line.get(lp.x, lp.y, p.x, p.y));
            }
          }
      }
    }
    return lines;
  }

  inline function get_control_count() return control_points.length;

  inline function update_curve_count() {
    curve_count = Math.floor((control_points.length - 1) / curve_mode).intMax(0);
  }

  inline function set_line_mode(v:BezierLineMode) {
    if (line_mode != v) dirty = true;
    return line_mode = v;
  }

  function set_curve_mode(v) {
    if (curve_mode != v) {
      curve_mode = v;
      update_curve_count();
      dirty = true;
    }
    return curve_mode;
  }
}

@:enum abstract BezierCurve(Int) to Int from Int {
  var Linear = 1;
  var Quadratic = 2;
  var Cubic = 3;
}

enum BezierLineMode {
  /**
   * Splits each Bezier Curve in the path into the defined `amount` of Line Segements.
   */
  Segments(amount:Int);
}
