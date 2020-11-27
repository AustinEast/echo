package echo.util;

import echo.shape.*;
import echo.data.Data;
import hxmath.math.Vector2;

using hxmath.math.MathUtil;
using echo.util.SAT;
using echo.util.Ext;
/**
 * Class containing methods to perform collision checks using the Separating Axis Thereom
 */
class SAT {
  static final norm = new Vector2(0, 0);
  static final closest = new Vector2(0, 0);

  public static inline function point_in_rect(p:Vector2, r:Rect):Bool {
    if (r.transformed_rect != null && r.rotation != 0) return p.point_in_polygon(r.transformed_rect);
    return r.left <= p.x && r.right >= p.x && r.top <= p.x && r.bottom >= p.y;
  }

  public static inline function point_in_circle(p:Vector2, c:Circle):Bool {
    return p.distanceTo(c.get_position()) < c.radius;
  }

  public static inline function point_in_polygon(point:Vector2, polygon:Polygon):Bool {
    var inside = false;
    var j = polygon.count - 1;

    for (i in 0...polygon.count) {
      var v = polygon.vertices;
      if ((v[i].y > point.y) != (v[j].y > point.y)
        && (point.x < (v[j].x - v[i].x) * (point.y - v[i].y) / (v[j].y - v[i].y) + v[i].x)) inside != inside;
      j = i;
    }

    return inside;
  }

  public static inline function rect_contains(r:Rect, v:Vector2):Bool {
    return point_in_rect(v, r);
  }

  public static inline function circle_contains(c:Circle, v:Vector2):Bool {
    return point_in_circle(v, c);
  }

  public static inline function polygon_contains(p:Polygon, v:Vector2):Bool {
    return point_in_polygon(v, p);
  }

  public static inline function line_intersects_line(line1:Line, line2:Line):Null<IntersectionData> {
    var d = ((line2.dy - line2.y) * (line1.dx - line1.x)) - ((line2.dx - line2.x) * (line1.dy - line1.y));

    if (d.equals(0)) return null;

    var ua = (((line2.dx - line2.x) * (line1.y - line2.y)) - ((line2.dy - line2.y) * (line1.x - line2.x))) / d;
    var ub = (((line1.dx - line1.x) * (line1.y - line2.y)) - ((line1.dy - line1.y) * (line1.x - line2.x))) / d;

    if ((ua < 0) || (ua > 1) || (ub < 0) || (ub > 1)) return null;

    var hit = line1.start + ua * (line1.end - line1.start);
    var distance = line1.start.distanceTo(hit);
    var overlap = line1.length - distance;
    var inverse = d >= 0;
    var l2l = line2.length * (inverse ? -1 : 1);
    norm.set((line2.dy - line2.y) / l2l, -(line2.dx - line2.x) / l2l);
    return IntersectionData.get(distance, overlap, hit.x, hit.y, norm.x, norm.y, inverse);
  }

  public static function line_intersects_rect(l:Line, r:Rect):Null<IntersectionData> {
    if (r.transformed_rect != null && r.rotation != 0) return r.transformed_rect.intersect(l);
    var closest:Null<IntersectionData> = null;

    var left = r.left;
    var right = r.right;
    var top = r.top;
    var bottom = r.bottom;

    var line = Line.get(left, top, right, top);
    var result = l.line_intersects_line(line);
    if (result != null) closest = result;

    line.set(right, top, right, bottom);
    result = l.line_intersects_line(line);
    if (result != null && (closest == null || closest.distance > result.distance)) closest = result;

    line.set(right, bottom, left, bottom);
    result = l.line_intersects_line(line);
    if (result != null && (closest == null || closest.distance > result.distance)) closest = result;

    line.set(left, bottom, left, top);
    result = l.line_intersects_line(line);
    if (result != null && (closest == null || closest.distance > result.distance)) closest = result;

    if (closest != null) {
      closest.line = l;
      closest.shape = r;
    }

    return closest;
  }

  public static function line_intersects_circle(l:Line, c:Circle):Null<IntersectionData> {
    var d = l.end - l.start;
    var f = l.start - c.get_position();
    var r = c.radius;

    var a = d * d;
    var b = 2 * (f * d);
    var e = (f * f) - (r * r);

    var discriminant = b * b - 4 * a * e;
    if (discriminant < 0) return null;

    discriminant = Math.sqrt(discriminant);

    var t1 = (-b - discriminant) / (2 * a);
    var t2 = (-b + discriminant) / (2 * a);

    if (t1 >= 0 && t1 <= 1) {
      var hit = l.point_along_ratio(t1);
      var distance = l.start.distanceTo(hit);
      var overlap = l.length - distance;
      norm.set(hit.x - c.x, hit.y - c.y).divideWith(r);

      var i = IntersectionData.get(distance, overlap, hit.x, hit.y, norm.x, norm.y);
      i.line = l;
      i.shape = c;
      return i;
    }

    if (t2 >= 0 && t2 <= 1) {
      var hit = l.point_along_ratio(t2);
      var distance = l.start.distanceTo(hit);
      var overlap = l.length - distance;
      norm.set(hit.x - c.x, hit.y - c.y).applyNegate().divideWith(r);

      var i = IntersectionData.get(distance, overlap, hit.x, hit.y, norm.x, norm.y, true);
      i.line = l;
      i.shape = c;
      return i;
    }

    // No intersection
    return null;
  }

  public static function line_intersects_polygon(l:Line, p:Polygon):Null<IntersectionData> {
    var closest:Null<IntersectionData> = null;
    var line = Line.get();

    for (i in 0...p.count) {
      line.set_from_vectors(p.vertices[i], p.vertices[(i + 1) % p.count]);
      var result = l.line_intersects_line(line);
      if (result != null && (closest == null || closest.distance > result.distance)) closest = result;
    }

    if (closest != null) {
      closest.line = l;
      closest.shape = p;
    }

    return closest;
  }

  public static inline function ray_intersects_rect(r:Ray, rect:Rect):Null<IntersectionData> {
    return null;
  }

  public static inline function ray_intersects_circle(r:Ray, c:Circle):Null<IntersectionData> {
    return null;
  }

  public static inline function ray_intersects_polygon(r:Ray, p:Polygon):Null<IntersectionData> {
    return null;
  }

  @:dox(hide)
  @:deprecated("`rect_intersects()` has been depricated - use `rect_intersects_line()` or `rect_intersects_ray()` instead.")
  public static inline function rect_intersects(r:Rect, l:Line):Null<IntersectionData> {
    return line_intersects_rect(l, r);
  }

  @:dox(hide)
  @:deprecated("`circle_intersects()` has been depricated - use `circle_intersects_line()` or `circle_intersects_ray()` instead.")
  public static inline function circle_intersects(c:Circle, l:Line):Null<IntersectionData> {
    return line_intersects_circle(l, c);
  }

  @:dox(hide)
  @:deprecated("`polygon_intersects()` has been depricated - use `polygon_intersects_line()` or `polygon_intersects_ray()` instead.")
  public static inline function polygon_intersects(p:Polygon, l:Line):Null<IntersectionData> {
    return line_intersects_polygon(l, p);
  }

  public static inline function rect_intersects_line(r:Rect, l:Line):Null<IntersectionData> {
    return line_intersects_rect(l, r);
  }

  public static inline function circle_intersects_line(c:Circle, l:Line):Null<IntersectionData> {
    return line_intersects_circle(l, c);
  }

  public static inline function polygon_intersects_line(p:Polygon, l:Line):Null<IntersectionData> {
    return line_intersects_polygon(l, p);
  }

  public static inline function rect_intersects_ray(rect:Rect, r:Ray):Null<IntersectionData> {
    return ray_intersects_rect(r, rect);
  }

  public static inline function circle_intersects_ray(c:Circle, r:Ray):Null<IntersectionData> {
    return ray_intersects_circle(r, c);
  }

  public static inline function polygon_intersects_ray(p:Polygon, r:Ray):Null<IntersectionData> {
    return ray_intersects_polygon(r, p);
  }
  /**
   * Test two Rects for a Collision.
   * @param rect1
   * @param rect2
   * @param flip
   * @return Null<CollisionData>
   */
  public static function rect_and_rect(rect1:Rect, rect2:Rect, flip:Bool = false):Null<CollisionData> {
    if (rect1.rotation != 0 || rect2.rotation != 0) {
      if (rect1.transformed_rect != null) {
        return rect_and_polygon(rect2, rect1.transformed_rect, flip);
      }
      if (rect2.transformed_rect != null) {
        return rect_and_polygon(rect1, rect2.transformed_rect, !flip);
      }
    }

    var sa = flip ? rect2 : rect1;
    var sb = flip ? rect1 : rect2;

    // Vector from A to B
    var nx = sb.x - sa.x;
    var ny = sb.y - sa.y;
    // Calculate overlap on x axis
    var x_overlap = sa.ex + sb.ex - Math.abs(nx);

    var col:CollisionData = null;
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
          col = CollisionData.get(x_overlap, nx < 0 ? -1 : 1, 0);
        }
        else {
          // Point toward B knowing that n points from A to B
          col = CollisionData.get(y_overlap, 0, ny < 0 ? -1 : 1);
        }
        col.sa = sa;
        col.sb = sb;
      }
    }

    return col;
  }
  /**
   * Test two Circles for a Collision.
   * @param circle1
   * @param circle2
   * @param flip
   * @return Null<CollisionData>
   */
  public static function circle_and_circle(circle1:Circle, circle2:Circle, flip:Bool = false):Null<CollisionData> {
    var sa = flip ? circle2 : circle1;
    var sb = flip ? circle1 : circle2;

    // Vector from sb to sa
    var nx = sb.x - sa.x;
    var ny = sb.y - sa.y;
    // radii of circles
    var r = sa.radius + sb.radius;
    // length squared
    var d = nx * nx + ny * ny;

    var col:CollisionData = null;

    // Do quick check if circles are colliding
    if (d >= r * r) return col;
    // If distance between circles is zero, make up a number
    else if (d.equals(0)) {
      col = CollisionData.get(sa.radius, 1, 0);
    }
    else {
      // Get actual square root
      d = Math.sqrt(d);
      // Distance is difference between radius and distance
      nx /= d;
      ny /= d;
      col = CollisionData.get(r - d, nx, ny);
    }

    col.sa = sa;
    col.sb = sb;

    return col;
  }
  /**
   * Test two Polygons for a Collision. Implementation ported from the [differ](https://github.com/snowkit/differ/blob/master/differ/sat/SAT2D.hx#L191) library.
   * @param polygon1
   * @param polygon2
   * @param flip
   * @return Null<CollisionData>
   */
  public static function polygon_and_polygon(polygon1:Polygon, polygon2:Polygon, flip:Bool = false):Null<CollisionData> {
    var data1:Null<CollisionData>;
    var data2:Null<CollisionData>;

    data1 = check_polygons(polygon1, polygon2, flip);
    if (data1 == null) return null;

    data2 = check_polygons(polygon2, polygon1, !flip);
    if (data2 == null) return null;

    // trace('data1: ${data1.overlap}, data2: ${data2.overlap}');

    if (data1.overlap < 0) {
      data1.overlap = Math.abs(data1.overlap);
    }
    if (data2.overlap < 0) {
      data2.overlap = Math.abs(data2.overlap);
    }

    if (data1.overlap < data2.overlap) {
      data2.put();
      return data1;
    }

    data1.put();
    return data2;
  }
  /**
   * Test a Rect and a Circle for a Collision.
   * @param r
   * @param c
   * @param flip
   * @return Null<CollisionData>
   */
  public static function rect_and_circle(r:Rect, c:Circle, flip:Bool = false):Null<CollisionData> {
    if (r.transformed_rect != null && r.rotation != 0) return circle_and_polygon(c, r.transformed_rect, flip);

    // Vector from A to B
    var nx = flip ? c.x - r.x : r.x - c.x;
    var ny = flip ? c.y - r.y : r.y - c.y;
    // Closest point on A to center of B
    var cx = nx;
    var cy = ny;

    // Clamp point to edges of the AABB
    cx = cx.clamp(-r.ex, r.ex);
    cy = cy.clamp(-r.ey, r.ey);
    var inside = false;
    var rad = c.radius;

    // Circle is inside the AABB, so we need to clamp the circle's center
    // to the closest edge
    if (nx.equals(cx) && ny.equals(cy)) {
      inside = true;
      // Find closest axis
      if (Math.abs(nx) > Math.abs(ny)) {
        // Clamp to closest extent
        cx = cx > 0 ? r.ex + rad + 0.1 : -r.ex - rad - 0.1;
      }
      else {
        // Clamp to closest extent
        cy = cy > 0 ? r.ey + rad + 0.1 : -r.ey - rad - 0.1;
      }
    }

    nx -= cx;
    ny -= cy;
    // length squared
    var d = nx * nx + ny * ny;

    // Early out if the radius is shorter than distance to closest point and
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

    var col = CollisionData.get(Math.abs(rad - d), nx, ny);
    col.sa = flip ? c : r;
    col.sb = flip ? r : c;

    return col;
  }

  public static function rect_and_polygon(r:Rect, p:Polygon, flip:Bool = false):Null<CollisionData> {
    if (r.transformed_rect != null) return polygon_and_polygon(r.transformed_rect, p, flip);

    var tr = Polygon.get_from_rect(r);
    @:privateAccess
    tr.set_parent(r.parent);
    var col = polygon_and_polygon(tr, p, flip);

    if (col == null) return null;

    if (flip) col.sb = r;
    else col.sa = r;
    tr.put();

    return col;
  }
  /**
   * Test a Circle and a Polygon for a Collision. Implementation ported from the [differ](https://github.com/snowkit/differ/blob/master/differ/sat/SAT2D.hx#L13) library.
   * @param c
   * @param p
   * @param flip
   * @return Null<CollisionData>
   */
  public static function circle_and_polygon(c:Circle, p:Polygon, flip:Bool = false):Null<CollisionData> {
    var distance:Float = 0;
    var testDistance:Float = 0x3FFFFFFF;
    var c_pos = c.get_position();
    var c_rad = c.radius;

    for (i in 0...p.count) {
      distance = (c_pos - p.vertices[i]).lengthSq;

      if (distance < testDistance) {
        testDistance = distance;
        closest.set(p.vertices[i].x, p.vertices[i].y);
      }
    }

    var normal = (closest - c_pos).normalize();

    // Project the polygon's points
    var test:Float = 0;
    var min1 = normal * p.vertices[0];
    var max1 = min1;

    for (j in 1...p.count) {
      test = normal * p.vertices[j];
      if (test < min1) min1 = test;
      if (test > max1) max1 = test;
    }

    // Project the circle
    var max2 = c_rad;
    var min2 = -c_rad;
    var offset = normal * -c_pos;

    min1 += offset;
    max1 += offset;

    var test1 = min1 - max2;
    var test2 = min2 - max1;

    // Test to see if we should exit early
    if (test1 > 0 || test2 > 0) return null;

    // Circle distance check
    var distMin = -(max2 - min1);
    if (flip) distMin *= -1;

    var col = CollisionData.get(distMin, normal.x, normal.y);
    var closest = Math.abs(distMin);

    // Find the normal axis for each point and project
    for (i in 0...p.count) {
      normal.set(p.normals[i].x, p.normals[i].y);

      // Project the polygon
      min1 = normal * p.vertices[0];
      max1 = min1;

      // Project all other points
      for (j in 1...p.count) {
        test = normal * p.vertices[j];
        if (test < min1) min1 = test;
        if (test > max1) max1 = test;
      }

      // Project the circle
      max2 = c_rad;
      min2 = -c_rad;

      // Offset points
      offset = normal * -c_pos;
      min1 += offset;
      max1 += offset;

      test1 = min1 - max2;
      test2 = min2 - max1;

      // Preform another test
      if (test1 > 0 || test2 > 0) {
        col.put();
        return null;
      }

      distMin = -(max2 - min1);
      if (flip) distMin *= -1;

      if (Math.abs(distMin) < closest) {
        col.normal.set(normal.x, normal.y);
        col.overlap = distMin;
        closest = Math.abs(distMin);
      }
    }

    col.sa = flip ? p : c;
    col.sb = flip ? c : p;
    // col.normal = into.unitVectorX * into.overlap;
    // into.separationY = into.unitVectorY * into.overlap;

    col.overlap = Math.abs(col.overlap);

    if (flip) {
      col.normal.applyNegate();
    }

    return col;
  }

  static function check_polygons(polygon1:Polygon, polygon2:Polygon, flip:Bool = false):Null<CollisionData> {
    var test1:Float = 0;
    var test2:Float = 0;
    var testNum:Float = 0;
    var min1:Float = 0;
    var max1:Float = 0;
    var min2:Float = 0;
    var max2:Float = 0;
    var closest:Float = 0x3FFFFFFF;
    var col:Null<CollisionData> = null;
    var normal = new Vector2(0, 0);

    // loop to begin projection
    for (i in 0...polygon1.count) {
      normal.set(polygon1.normals[i].x, polygon1.normals[i].y);

      // project polygon1
      max1 = min1 = normal * polygon1.vertices[0];

      for (j in 1...polygon1.count) {
        testNum = normal * polygon1.vertices[j];
        if (testNum < min1) min1 = testNum;
        if (testNum > max1) max1 = testNum;
      }

      // project polygon2
      max2 = min2 = normal * polygon2.vertices[0];

      for (j in 1...polygon2.count) {
        testNum = normal * polygon2.vertices[j];
        if (testNum < min2) min2 = testNum;
        if (testNum > max2) max2 = testNum;
      }

      test1 = min1 - max2;
      test2 = min2 - max1;

      if (test1 > 0 || test2 > 0) return null;

      var overlap = -(max2 - min1);
      if (flip) overlap *= -1;

      if (Math.abs(overlap) < closest) {
        if (col == null) col = CollisionData.get(overlap, normal.x, normal.y);
        else col.set(overlap, normal.x, normal.y);
        closest = Math.abs(overlap);
      }
    }

    if (col == null) return null;

    col.sa = flip ? polygon2 : polygon1;
    col.sb = flip ? polygon1 : polygon2;

    if (flip) {
      col.normal.applyNegate();
    }

    return col;
  }
}
