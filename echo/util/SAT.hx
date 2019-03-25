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
    var nx = sb.position.x - sa.position.x;
    var ny = sb.position.y - sa.position.y;
    // Calculate overlap on x axis
    var x_overlap = sa.ex + sb.ex - Math.abs(nx);
    // SAT test on x axis
    if (x_overlap > 0) {
      // Calculate overlap on y axis
      var y_overlap = sa.ey + sb.ey - Math.abs(ny);
      // SAT test on y axis.
      // If both axis overlap, the boxes are colliding
      if (y_overlap > 0) {
        // Find out which axis is axis of least penetration
        if (x_overlap < y_overlap) {
          // Point towards B knowing that n points from A to B
          return CollisionData.get(x_overlap, nx < 0 ? -1 : 1, 0);
        }
        else {
          // Point toward B knowing that n points from A to B
          return CollisionData.get(y_overlap, 0, ny < 0 ? -1 : 1);
        }
      }
    }

    return null;
  }

  public static function circle_and_circle(circle1:Circle, circle2:Circle, flip:Bool = false):Null<CollisionData> {
    var sa = flip ? circle2 : circle1;
    var sb = flip ? circle1 : circle2;

    // Vector from sb to sa
    var nx = sb.position.x - sa.position.x;
    var ny = sb.position.y - sa.position.y;
    // radii of circles
    var r = sa.radius + sb.radius;
    // length squared
    var d = nx * nx + ny * ny;

    // Do quick check if circles are colliding
    if (d >= r * r) return null;
    // If distance between circles is zero, make up a number
    else if (d == 0) {
      return CollisionData.get(sa.radius, 1, 0);
    }
    else {
      // Get actual square root
      d = Math.sqrt(d);
      // Distance is difference between radius and distance
      nx /= d;
      ny /= d;
      return CollisionData.get(r - d, nx, ny);
    }
  }

  public static function rect_and_circle(r:Rect, c:Circle, flip:Bool = false):Null<CollisionData> {
    // Vector from A to B
    var nx = flip ? c.position.x - r.position.x : r.position.x - c.position.x;
    var ny = flip ? c.position.y - r.position.y : r.position.y - c.position.y;
    // Closest point on A to center of B
    var cx = nx;
    var cy = ny;

    // Clamp point to edges of the AABB
    cx = cx.clamp(-r.ex, r.ex);
    cy = cy.clamp(-r.ey, r.ey);
    var inside = false;

    // Circle is inside the AABB, so we need to clamp the circle's center
    // to the closest edge
    if (nx == cx && ny == cy) {
      inside = true;
      // Find closest axis
      if (Math.abs(nx) > Math.abs(ny)) {
        // Clamp to closest extent
        cx = cx > 0 ? r.ex + c.radius + 0.1 : -r.ex - c.radius - 0.1;
      }
      else {
        // Clamp to closest extent
        cy = cy > 0 ? r.ey + c.radius + 0.1 : -r.ey - c.radius - 0.1;
      }
    }

    nx -= cx;
    ny -= cy;
    // length squared
    var d = nx * nx + ny * ny;
    var rad = c.radius;

    // Early out of the radius is shorter than distance to closest point and
    // Circle not inside the AABB
    if (d > rad * rad && !inside) return null;

    // Avoided sqrt until we needed
    d = Math.sqrt(d);
    nx /= d;
    ny /= d;

    // Collision normal needs to be flipped to point outside if circle was inside the AABB
    if (inside) {
      nx *= -1;
      ny *= -1;
    }
    return CollisionData.get(Math.abs(rad - d), nx, ny);
  }
}
