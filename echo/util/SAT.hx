package echo.util;

import echo.shape.*;
import hxmath.math.Vector2;

using hxmath.math.MathUtil;

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
    var s1 = flip ? rect2 : rect1;
    var s2 = flip ? rect1 : rect2;

    // Vector from A to B
    var n = s2.position - s1.position;
    // Calculate overlap on x axis
    var x_overlap = s1.ex + s2.ex - Math.abs(n.x);
    // SAT test on x axis
    if (x_overlap > 0) {
      // Calculate overlap on y axis
      var y_overlap = s1.ey + s2.ey - Math.abs(n.y);
      // SAT test on y axis.
      // If both axis overlap, the boxes are colliding
      if (y_overlap > 0) {
        // Find out which axis is axis of least penetration
        if (x_overlap < y_overlap) {
          // Point towards B knowing that n points from A to B
          return {
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
    var s1 = flip ? circle2 : circle1;
    var s2 = flip ? circle1 : circle2;

    // Vector2 from s2 to s1
    var n = s2.position - s1.position;
    // radii of circles
    var r = s1.radius + s2.radius;
    var d = n.lengthSq;

    // Do quick check if circles are colliding
    if (d >= r * r) return null;
    // If distance between circles is zero, make up a number
    else if (d == 0) {
      return {
        overlap: s1.radius,
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

    var ex = (r.right - r.left) / 2;
    var ey = (r.bottom - r.top) / 2;

    // Clamp point to edges of the AABB
    closest.x = closest.x.clamp(-ex, ex);
    closest.y = closest.y.clamp(-ey, ey);
    var inside = false;

    // Circle is inside the AABB, so we need to clamp the circle's center
    // to the closest edge
    if (n == closest) {
      inside = true;
      // Find closest axis
      if (Math.abs(n.x) > Math.abs(n.y)) {
        // Clamp to closest extent
        closest.x = closest.x > 0 ? ex : -ex;
      }
      else {
        // Clamp to closest extent
        closest.y = closest.y > 0 ? ey : -ey;
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

    // Collision normal needs to be flipped to point outside if circle was
    // inside the AABB
    return {
      normal: inside ? normal * -1 : normal,
      overlap: rad - d
    };
  }
}

typedef CollisionData = {
  /**
   * The length of shape 1's penetration into shape 2.
   */
  var overlap:Float;
  /**
   * The normal vector (direction) of shape 1's penetration into shape 2.
   */
  var normal:Vector2;
  /**
   * TODO: Provide a direction const, similar to Flixel's
   */
  var ?direction:Int;
}

typedef IntersectionData = {}
