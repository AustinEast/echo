package echo.util;

import echo.shape.*;
import echo.data.Data;
import hxmath.math.Vector2;

using hxmath.math.MathUtil;
/**
 * Class containing methods to perform collision checks using the Separating Axis Thereom
 */
class SAT {
  public static inline function point_in_rect(p:Vector2, r:Rect):Bool {
    return r.left <= p.x && r.right >= p.x && r.top <= p.x && r.bottom >= p.y;
  }

  public static inline function point_in_circle(p:Vector2, c:Circle):Bool {
    return p.distanceTo(c.position) < c.radius;
  }

  public static inline function rect_contains(r:Rect, p:Vector2):Bool {
    return point_in_rect(p, r);
  }

  public static inline function circle_contains(c:Circle, p:Vector2):Bool {
    return point_in_circle(p, c);
  }

  public static inline function line_interects_rect(l:Line, r:Rect):Null<IntersectionData> {
    return null;
  }

  public static inline function line_intersects_circle(l:Line, c:Circle):Null<IntersectionData> {
    return null;
  }

  public static inline function rect_intersects(r:Rect, l:Line):Null<IntersectionData> {
    return line_interects_rect(l, r);
  }

  public static inline function circle_intersects(c:Circle, l:Line):Null<IntersectionData> {
    return line_intersects_circle(l, c);
  }

  public static function rect_and_rect(rect1:Rect, rect2:Rect, flip:Bool = false):Null<CollisionData> {
    var sa = flip ? rect2 : rect1;
    var sb = flip ? rect1 : rect2;

    // Vector from A to B
    var n = sb.position - sa.position;
    // Calculate overlap on x axis
    var x_overlap = sa.ex + sb.ex - Math.abs(n.x);
    // SAT test on x axis
    if (x_overlap > 0) {
      // Calculate overlap on y axis
      var y_overlap = sa.ey + sb.ey - Math.abs(n.y);
      // SAT test on y axis.
      // If both axis overlap, the boxes are colliding
      if (y_overlap > 0) {
        // Find out which axis is axis of least penetration
        if (x_overlap < y_overlap) {
          // Point towards B knowing that n points from A to B
          return {
            sa: sa,
            sb: sb,
            normal: n.x < 0 ? new Vector2(-1, 0) : new Vector2(1, 0),
            overlap: x_overlap
          };
        }
        else {
          // Point toward B knowing that n points from A to B
          return {
            normal: n.y < 0 ? new Vector2(0, -1) : new Vector2(0, 1),
            overlap: y_overlap
          }
        }
      }
    }

    return null;
  }

  public static function circle_and_circle(circle1:Circle, circle2:Circle, flip:Bool = false):Null<CollisionData> {
    var sa = flip ? circle2 : circle1;
    var sb = flip ? circle1 : circle2;

    // Vector2 from sb to sa
    var n = sb.position - sa.position;
    // radii of circles
    var r = sa.radius + sb.radius;
    var d = n.lengthSq;

    // Do quick check if circles are colliding
    if (d >= r * r) return null;
    // If distance between circles is zero, make up a number
    else if (d == 0) {
      return {
        overlap: sa.radius,
        normal: new Vector2(1, 0)
      };
    }
    else {
      // Get actual square root
      d = Math.sqrt(d);
      // Distance is difference between radius and distance
      return {
        overlap: r - d,
        normal: n / d
      };
    }
  }

  public static function rect_and_circle(r:Rect, c:Circle, flip:Bool = false):Null<CollisionData> {
    // Vector from A to B
    var n = flip ? c.position - r.position : r.position - c.position;
    // Closest point on A to center of B
    var closest = n.clone();

    // Clamp point to edges of the AABB
    closest.x = closest.x.clamp(-r.ex, r.ex);
    closest.y = closest.y.clamp(-r.ey, r.ey);
    var inside = false;

    // Circle is inside the AABB, so we need to clamp the circle's center
    // to the closest edge
    if (n == closest) {
      inside = true;
      // Find closest axis
      if (Math.abs(n.x) > Math.abs(n.y)) {
        // Clamp to closest extent
        closest.x = closest.x > 0 ? r.ex + c.radius + 0.1 : -r.ex - c.radius - 0.1;
      }
      else {
        // Clamp to closest extent
        closest.y = closest.y > 0 ? r.ey + c.radius + 0.1 : -r.ey - c.radius - 0.1;
      }
    }

    var normal = n - closest;
    var d = normal.lengthSq;
    var rad = c.radius;

    // Early out of the radius is shorter than distance to closest point and
    // Circle not inside the AABB
    if (d > rad * rad && !inside) return null;

    // Avoided sqrt until we needed
    d = Math.sqrt(d);
    normal.normalize();

    // Collision normal needs to be flipped to point outside if circle was inside the AABB
    return {
      normal: inside ? -normal : normal,
      overlap: Math.abs(rad - d)
    };
  }
}
