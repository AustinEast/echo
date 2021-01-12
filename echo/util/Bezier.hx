package echo.util;

import echo.util.Disposable;
import hxmath.math.Vector2;

using Math;
using hxmath.math.MathUtil;

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
   * Ported from https://github.com/mattdesl/adaptive-quadratic-curve
   */
  public static function subdivide_quadratic_bezier_curve(ax:Float, ay:Float, bx:Float, by:Float, cx:Float, cy:Float, ?points:Array<Vector2>,
      options:BezierSubdivisionOptions) {
    final n = options != null;
    final recursion_limit = n && options.recursion_limit != null ? options.recursion_limit : 8;
    final flt_epsilon = n && options.epsilon != null ? options.epsilon : 1.19209290e-7;
    final path_distance_epsilon = n && options.path_epsilon != null ? options.path_epsilon : 1.0;
    final curve_angle_tolerance_epsilon = n && options.angle_epsilon != null ? options.angle_epsilon : 0.01;
    final m_angle_tolerance = n && options.angle_tolerance != null ? options.angle_tolerance : 0.0;

    function recursive(ax:Float, ay:Float, bx:Float, by:Float, cx:Float, cy:Float, ?points:Array<Vector2>, distance_tolerance:Float, level:Int) {
      if (level > recursion_limit) return;

      var pi = Math.PI;

      // Calculate all the mid-points of the line segments
      //----------------------
      var xab = (ax + bx) / 2;
      var yab = (ay + by) / 2;
      var xbc = (bx + cx) / 2;
      var ybc = (by + cy) / 2;
      var xabc = (xab + xbc) / 2;
      var yabc = (yab + ybc) / 2;

      var dx = cx - ax;
      var dy = cy - ay;
      var d = Math.abs(((bx - cx) * dy - (by - cy) * dx));

      if (d > flt_epsilon) {
        // Regular care
        //-----------------
        if (d * d <= distance_tolerance * (dx * dx + dy * dy)) {
          // If the curvature doesn't exceed the distance_tolerance value
          // we tend to finish subdivisions.
          //----------------------
          if (m_angle_tolerance < curve_angle_tolerance_epsilon) {
            points.push(new Vector2(xabc, yabc));
            return;
          }

          // Angle & Cusp Condition
          //----------------------
          var da = Math.abs(Math.atan2(cy - by, cx - bx) - Math.atan2(by - ay, bx - ax));
          if (da >= pi) da = 2 * pi - da;

          if (da < m_angle_tolerance) {
            // Finally we can stop the recursion
            //----------------------
            points.push(new Vector2(xabc, yabc));
            return;
          }
        }
      }
      else {
        // Collinear case
        //-----------------
        dx = xabc - (ax + cx) / 2;
        dy = yabc - (ay + cy) / 2;
        if (dx * dx + dy * dy <= distance_tolerance) {
          points.push(new Vector2(xabc, yabc));
          return;
        }
      }

      // Continue subdivision
      //----------------------
      recursive(ax, ay, xab, yab, xabc, yabc, points, distance_tolerance, level + 1);
      recursive(xabc, yabc, xbc, ybc, cx, cy, points, distance_tolerance, level + 1);
    }

    final scale = n && options.scale != null ? options.scale : 1.0;
    var distance_tolerance = path_distance_epsilon / scale;
    distance_tolerance *= distance_tolerance;
    points.push(new Vector2(ax, ay));
    recursive(ax, ay, bx, by, cx, cy, points, distance_tolerance, 0);
    points.push(new Vector2(cx, cy));
    return points;
  }
  /**
   * Ported from https://github.com/mattdesl/adaptive-bezier-curve
   */
  public static function subdivide_cubic_bezier_curve(ax:Float, ay:Float, bx:Float, by:Float, cx:Float, cy:Float, dx:Float, dy:Float, ?points:Array<Vector2>,
      options:BezierSubdivisionOptions) {
    final n = options != null;
    final recursion_limit = n && options.recursion_limit != null ? options.recursion_limit : 8;
    final flt_epsilon = n && options.epsilon != null ? options.epsilon : 1.19209290e-7;
    final path_distance_epsilon = n && options.path_epsilon != null ? options.path_epsilon : 1.0;
    final curve_angle_tolerance_epsilon = n && options.angle_epsilon != null ? options.angle_epsilon : 0.01;
    final m_angle_tolerance = n && options.angle_tolerance != null ? options.angle_tolerance : 0.0;
    final m_cusp_limit = n && options.cusp_limit != null ? options.cusp_limit : 0.0;

    function recursive(ax:Float, ay:Float, bx:Float, by:Float, cx:Float, cy:Float, dx:Float, dy:Float, points:Array<Vector2>, distance_tolerance:Float,
        level:Int) {
      if (level > recursion_limit) return;

      var pi = Math.PI;

      // Calculate all the mid-points of the line segments
      //----------------------
      var xab = (ax + bx) / 2;
      var yab = (ay + by) / 2;
      var xbc = (bx + cx) / 2;
      var ybc = (by + cy) / 2;
      var xcd = (cx + dx) / 2;
      var ycd = (cy + dy) / 2;
      var xabc = (xab + xbc) / 2;
      var yabc = (yab + ybc) / 2;
      var xbcd = (xbc + xcd) / 2;
      var ybcd = (ybc + ycd) / 2;
      var xabcd = (xabc + xbcd) / 2;
      var yabcd = (yabc + ybcd) / 2;

      if (level > 0) { // Enforce subdivision first time
        // Try to approximate the full cubic curve by a single straight line
        //------------------
        var rx = dx - ax;
        var ry = dy - ay;

        var d2 = Math.abs((bx - dx) * ry - (by - dy) * rx);
        var d3 = Math.abs((cx - dx) * ry - (cy - dy) * rx);

        var da1;
        var da2;

        if (d2 > flt_epsilon && d3 > flt_epsilon) {
          // Regular care
          //-----------------
          if ((d2 + d3) * (d2 + d3) <= distance_tolerance * (rx * rx + ry * ry)) {
            // If the curvature doesn't exceed the distanceTolerance value
            // we tend to finish subdivisions.
            //----------------------
            if (m_angle_tolerance < curve_angle_tolerance_epsilon) {
              points.push(new Vector2(xabcd, yabcd));
              return;
            }

            // Angle & Cusp Condition
            //----------------------
            var a23 = Math.atan2(cy - by, cx - bx);
            da1 = Math.abs(a23 - Math.atan2(by - ay, bx - ax));
            da2 = Math.abs(Math.atan2(dy - cy, dx - cx) - a23);
            if (da1 >= pi) da1 = 2 * pi - da1;
            if (da2 >= pi) da2 = 2 * pi - da2;
            if (da1 + da2 < m_angle_tolerance) {
              // Finally we can stop the recursion
              //----------------------
              points.push(new Vector2(xabcd, yabcd));
              return;
            }

            if (m_cusp_limit != 0.0) {
              if (da1 > m_cusp_limit) {
                points.push(new Vector2(bx, by));
                return;
              }

              if (da2 > m_cusp_limit) {
                points.push(new Vector2(cx, cy));
                return;
              }
            }
          }
        }
        else {
          if (d2 > flt_epsilon) {
            // p1,p3,p4 are collinear, p2 is considerable
            //----------------------
            if (d2 * d2 <= distance_tolerance * (rx * rx + ry * ry)) {
              if (m_angle_tolerance < curve_angle_tolerance_epsilon) {
                points.push(new Vector2(xabcd, yabcd));
                return;
              }

              // Angle Condition
              //----------------------
              da1 = Math.abs(Math.atan2(cy - by, cx - bx) - Math.atan2(by - ay, bx - ax));
              if (da1 >= pi) da1 = 2 * pi - da1;
              if (da1 < m_angle_tolerance) {
                points.push(new Vector2(bx, by));
                points.push(new Vector2(cx, cy));
                return;
              }

              if (m_cusp_limit != 0.0) {
                if (da1 > m_cusp_limit) {
                  points.push(new Vector2(bx, by));
                  return;
                }
              }
            }
          }
          else if (d3 > flt_epsilon) {
            // p1,p2,p4 are collinear, p3 is considerable
            //----------------------
            if (d3 * d3 <= distance_tolerance * (rx * rx + ry * ry)) {
              if (m_angle_tolerance < curve_angle_tolerance_epsilon) {
                points.push(new Vector2(xabcd, yabcd));
                return;
              }

              // Angle Condition
              //----------------------
              da1 = Math.abs(Math.atan2(dy - cy, dx - cx) - Math.atan2(cy - by, cx - bx));
              if (da1 >= pi) da1 = 2 * pi - da1;
              if (da1 < m_angle_tolerance) {
                points.push(new Vector2(bx, by));
                points.push(new Vector2(cx, cy));
                return;
              }

              if (m_cusp_limit != 0.0) {
                if (da1 > m_cusp_limit) {
                  points.push(new Vector2(cx, cy));
                  return;
                }
              }
            }
          }
          else {
            // Collinear case
            //-----------------
            rx = xabcd - (ax + dx) / 2;
            ry = yabcd - (ay + dy) / 2;
            if (rx * rx + ry * ry <= distance_tolerance) {
              points.push(new Vector2(xabcd, yabcd));
              return;
            }
          }
        }
      }

      // Continue subdivision
      //----------------------
      recursive(ax, ay, xab, yab, xabc, yabc, xabcd, yabcd, points, distance_tolerance, level + 1);
      recursive(xabcd, yabcd, xbcd, ybcd, xcd, ycd, dx, dy, points, distance_tolerance, level + 1);
    }

    if (points == null) points = [];

    final scale = n && options.scale != null ? options.scale : 1.0;
    var distance_tolerance = path_distance_epsilon / scale;
    distance_tolerance *= distance_tolerance;
    points.push(new Vector2(ax, ay));
    recursive(ax, ay, bx, by, cx, cy, dx, dy, points, distance_tolerance, 0);
    points.push(new Vector2(dx, dy));
    return points;
  }
  /**
   * Cached Array of Lines that represents the current state of the Curve.
   */
  public var lines(get, null):Array<Line> = [];
  /**
   * The method used to construct `lines` from the Curve.
   */
  public var line_mode(default, set):BezierLineMode = Subdivisions();
  /**
   * The amount of control points in this Curve.
   */
  public var control_count(get, never):Int;

  public var curve_mode(default, set):BezierCurve;

  public var curve_count(default, null):Int = 0;

  public var on_dirty:Bezier->Void;

  var control_points:Array<Vector2>;

  var dirty:Bool = true;

  public function new(?control_points:Array<Vector2>, curve_mode:BezierCurve = Cubic) {
    this.control_points = control_points != null ? control_points : [];
    this.curve_mode = curve_mode;
    update_curve_count();
    set_dirty();
  }

  public function dispose() {
    control_points = null;
    lines = null;
  }

  public function add_control_point(x:Float, y:Float) {
    control_points.push(new Vector2(x, y));
    update_curve_count();
    set_dirty();
  }

  public inline function get_control_point(index:Int):Null<Vector2> {
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
    set_dirty();
  }

  public inline function remove_control_point(index:Int) {
    control_points.splice(index, 1);
    update_curve_count();
    set_dirty();
  }

  public inline function remove_all_control_points() {
    control_points.resize(0);
    update_curve_count();
    set_dirty();
  }
  /**
   * Gets the point on the Curve at the defined `t`.
   * @param t A value between 0.0 to 1.0.
   * @param start_index Determines the starting control point that will be used to construct the Curve. If set to -1, this will be determined automatically based on `t`.
   */
  public inline function get_point(t:Float, start_index:Int = -1):Null<Vector2> {
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
        case Subdivisions(options):
          var points = [];
          for (j in 0...curve_count) {
            var start_index = j * curve_mode;
            var a = get_control_point(start_index);
            var b = get_control_point(start_index + 1);
            var c = get_control_point(start_index + 2);
            if (curve_mode == Quadratic) subdivide_quadratic_bezier_curve(a.x, a.y, b.x, b.y, c.x, c.y, points, options);
            else {
              var d = get_control_point(start_index + 3);
              subdivide_cubic_bezier_curve(a.x, a.y, b.x, b.y, c.x, c.y, d.x, d.y, points, options);
            }
          }
          for (i in 0...points.length) {
            if (i + 1 < points.length) lines.push(Line.get_from_vectors(points[i], points[i + 1]));
          }
      }
    }
    return lines;
  }

  public function set_dirty() {
    if (!dirty && on_dirty != null) on_dirty(this);
    dirty = true;
  }

  inline function get_control_count() return control_points.length;

  inline function update_curve_count() {
    curve_count = Math.floor((control_points.length - 1) / curve_mode).intMax(0);
  }

  inline function set_line_mode(v:BezierLineMode) {
    if (line_mode != v) set_dirty();
    return line_mode = v;
  }

  function set_curve_mode(v) {
    if (curve_mode != v) {
      curve_mode = v;
      update_curve_count();
      set_dirty();
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

  Subdivisions(?options:BezierSubdivisionOptions);
}

typedef BezierSubdivisionOptions = {
  ?scale:Float,
  ?recursion_limit:Int,
  ?epsilon:Float,
  ?path_epsilon:Float,
  ?angle_epsilon:Float,
  ?angle_tolerance:Float,
  ?cusp_limit:Float,
}
