package echo.util;

import echo.data.Data;
import echo.shape.*;
import echo.math.Vector2;

using echo.util.ext.FloatExt;
using echo.util.SAT;
/**
 * Class containing methods to perform collision checks using the Separating Axis Thereom
 */
class SAT {
  static final norm = new Vector2(0, 0);
  static final closest = new Vector2(0, 0);

  // Scratch vectors used during contact point generation
  static final ref_normal = new Vector2(0, 0);
  static final inc_normal = new Vector2(0, 0);
  static final side_normal = new Vector2(0, 0);
  static final inc0 = new Vector2(0, 0);
  static final inc1 = new Vector2(0, 0);

  public static inline function point_in_rect(p:Vector2, r:Rect):Bool {
    if (r.transformed_rect != null && r.rotation != 0) return p.point_in_polygon(r.transformed_rect);
    return r.left <= p.x && r.right >= p.x && r.top <= p.y && r.bottom >= p.y;
  }

  public static inline function point_in_circle(p:Vector2, c:Circle):Bool {
    return (p - c.get_position()).length_sq < c.radius * c.radius;
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
    var distance = line1.start.distance(hit);
    var overlap = line1.length - distance;
    var inverse = d >= 0;
    var l2l = line2.length * (inverse ? -1 : 1);
    norm.set((line2.dy - line2.y) / l2l, -(line2.dx - line2.x) / l2l);
    var data = IntersectionData.get(distance, overlap, hit.x, hit.y, norm.x, norm.y, inverse);
    data.line = line1;
    data.line2 = line2;
    return data;
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

    var a = d.dot(d);
    var b = 2 * f.dot(d);
    var e = f.dot(f) - (r * r);

    var discriminant = b * b - 4 * a * e;
    if (discriminant < 0) return null;

    discriminant = Math.sqrt(discriminant);

    var t1 = (-b - discriminant) / (2 * a);
    var t2 = (-b + discriminant) / (2 * a);

    if (t1 >= 0 && t1 <= 1) {
      var hit = l.point_along_ratio(t1);
      var distance = l.start.distance(hit);
      var overlap = l.length - distance;
      norm.set(hit.x - c.x, hit.y - c.y);
      norm /= r;

      var i = IntersectionData.get(distance, overlap, hit.x, hit.y, norm.x, norm.y);
      i.line = l;
      i.shape = c;
      return i;
    }

    if (t2 >= 0 && t2 <= 1) {
      var hit = l.point_along_ratio(t2);
      var distance = l.start.distance(hit);
      var overlap = l.length - distance;
      norm.set(hit.x - c.x, hit.y - c.y);
      norm.copy_from(-norm / r);

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

  public static inline function rect_intersects(r:Rect, l:Line):Null<IntersectionData> {
    return line_intersects_rect(l, r);
  }

  public static inline function circle_intersects(c:Circle, l:Line):Null<IntersectionData> {
    return line_intersects_circle(l, c);
  }

  public static inline function polygon_intersects(p:Polygon, l:Line):Null<IntersectionData> {
    return line_intersects_polygon(l, p);
  }
  /**
   * Test two Rects for a Collision.
   * @param rect1
   * @param rect2
   * @param flip
   * @return Null<CollisionData>
   */
  public static function rect_and_rect(rect1:Rect, rect2:Rect, flip:Bool = false):Null<CollisionData> {
    var col:CollisionData = null;
    if (rect1.rotation != 0 || rect2.rotation != 0) {
      if (rect1.transformed_rect != null) {
        col = rect_and_polygon(rect2, rect1.transformed_rect, !flip);

        if (col == null) return null;

        if (flip) col.sa = rect2;
        else col.sb = rect1;

        return col;
      }
      if (rect2.transformed_rect != null) {
        col = rect_and_polygon(rect1, rect2.transformed_rect, flip);

        if (col == null) return null;

        if (flip) col.sa = rect2;
        else col.sb = rect2;

        return col;
      }
    }

    var sa = flip ? rect2 : rect1;
    var sb = flip ? rect1 : rect2;

    // Vector from A to B
    var nx = sb.x - sa.x;
    var ny = sb.y - sa.y;
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
        // The contact points lie on the edges of the overlapping region, perpendicular to the normal
        var ox_min = Math.max(sa.left, sb.left);
        var ox_max = Math.min(sa.right, sb.right);
        var oy_min = Math.max(sa.top, sb.top);
        var oy_max = Math.min(sa.bottom, sb.bottom);
        if (x_overlap < y_overlap) {
          // Point towards B knowing that n points from A to B
          col = CollisionData.get(x_overlap, nx < 0 ? -1 : 1, 0);
          var cx = (ox_min + ox_max) * 0.5;
          col.add_contact(cx, oy_min);
          if (oy_max > oy_min) col.add_contact(cx, oy_max);
        }
        else {
          // Point toward B knowing that n points from A to B
          col = CollisionData.get(y_overlap, 0, ny < 0 ? -1 : 1);
          var cy = (oy_min + oy_max) * 0.5;
          col.add_contact(ox_min, cy);
          if (ox_max > ox_min) col.add_contact(ox_max, cy);
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
      col.add_contact(sa.x, sa.y);
    }
    else {
      // Get actual square root
      d = Math.sqrt(d);
      // Distance is difference between radius and distance
      nx /= d;
      ny /= d;
      col = CollisionData.get(r - d, nx, ny);
      // Contact point is halfway into the penetration, along the normal from A's center
      var cd = sa.radius - col.overlap * 0.5;
      col.add_contact(sa.x + nx * cd, sa.y + ny * cd);
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
    // Test polygon1's face normals
    if (!check_polygons(polygon1, polygon2)) return null;
    var overlap1 = sat_overlap;
    var nx1 = sat_nx;
    var ny1 = sat_ny;

    // Test polygon2's face normals
    if (!check_polygons(polygon2, polygon1)) return null;

    // Use the axis of least penetration. The stored normals point into the polygon that owns the face, so they are oriented here to
    // point from Shape A to Shape B (where A is polygon1, unless flipped).
    var col:CollisionData;
    if (overlap1 < sat_overlap) col = flip ? CollisionData.get(overlap1, nx1, ny1) : CollisionData.get(overlap1, -nx1, -ny1);
    else col = flip ? CollisionData.get(sat_overlap, -sat_nx, -sat_ny) : CollisionData.get(sat_overlap, sat_nx, sat_ny);

    col.sa = flip ? polygon2 : polygon1;
    col.sb = flip ? polygon1 : polygon2;

    clip_polygons(cast col.sa, cast col.sb, col);
    return col;
  }
  /**
   * Generates the contact points for a Collision between two Polygons, by clipping the incident face of one Polygon against the reference face of the other (the same approach used by Box2D).
   * @param a The first Polygon (`cd.sa`).
   * @param b The second Polygon (`cd.sb`).
   * @param cd The Collision, whose `normal` must point from `a` to `b`. Up to 2 contact points are added to it.
   */
  public static function clip_polygons(a:Polygon, b:Polygon, cd:CollisionData) {
    var nx = cd.normal.x;
    var ny = cd.normal.y;
    var face_a = best_face(a, nx, ny, ref_normal);
    var face_b = best_face(b, -nx, -ny, inc_normal);
    if (face_a < 0 || face_b < 0) return;

    // The reference face is the one whose normal is most parallel with the collision normal. The other face is the incident face.
    var dot_a = ref_normal.x * nx + ref_normal.y * ny;
    var dot_b = -(inc_normal.x * nx + inc_normal.y * ny);
    var ref:Polygon;
    var inc:Polygon;
    var ref_face:Int;
    var inc_face:Int;
    if (dot_b > dot_a + 0.0001) {
      ref = b;
      inc = a;
      ref_face = face_b;
      inc_face = face_a;
      ref_normal.set(inc_normal.x, inc_normal.y);
    }
    else {
      ref = a;
      inc = b;
      ref_face = face_a;
      inc_face = face_b;
    }

    var rv = ref.vertices;
    var r1 = rv[ref_face];
    var r2 = rv[(ref_face + 1) % ref.count];
    var iv = inc.vertices;
    var i1 = iv[inc_face];
    var i2 = iv[(inc_face + 1) % inc.count];
    inc0.set(i1.x, i1.y);
    inc1.set(i2.x, i2.y);

    // Clip the incident face to the sides of the reference face
    side_normal.set(r2.x - r1.x, r2.y - r1.y);
    side_normal.normalize();
    var neg_side = -(side_normal.x * r1.x + side_normal.y * r1.y);
    var pos_side = side_normal.x * r2.x + side_normal.y * r2.y;
    if (clip_segment(-side_normal.x, -side_normal.y, neg_side) < 2) return;
    if (clip_segment(side_normal.x, side_normal.y, pos_side) < 2) return;

    // Keep the clipped points that are behind the reference face, positioned halfway into the penetration
    var ref_c = ref_normal.x * r1.x + ref_normal.y * r1.y;
    var sep0 = ref_normal.x * inc0.x + ref_normal.y * inc0.y - ref_c;
    var sep1 = ref_normal.x * inc1.x + ref_normal.y * inc1.y - ref_c;
    if (sep0 <= 0) cd.add_contact(inc0.x - ref_normal.x * sep0 * 0.5, inc0.y - ref_normal.y * sep0 * 0.5);
    if (sep1 <= 0 && !(inc1.x == inc0.x && inc1.y == inc0.y)) cd.add_contact(inc1.x - ref_normal.x * sep1 * 0.5, inc1.y - ref_normal.y * sep1 * 0.5);

    // If numerical error left no contacts, fall back to the deepest incident vertex
    if (cd.contact_count == 0) {
      if (sep0 < sep1) cd.add_contact(inc0.x, inc0.y);
      else cd.add_contact(inc1.x, inc1.y);
    }
  }
  /**
   * Finds the face of a Polygon whose outward normal is most aligned with the direction (`dx`, `dy`).
   *
   * Face normals are computed here (rather than using `Polygon.normals`) so that the result is independent of the Polygon's winding order.
   * @return The index of the face's first vertex, or -1 if the Polygon is degenerate. The face's outward normal is written to `out_normal`.
   */
  static function best_face(p:Polygon, dx:Float, dy:Float, out_normal:Vector2):Int {
    var norms = p.normals;
    var count = p.count;
    if (count < 2) return -1;

    // The cached normals may point into or out of the polygon depending on its winding - flip them to point outward
    var sign = p.normals_outward ? 1. : -1.;
    var best = -1;
    var best_dot = Math.NEGATIVE_INFINITY;
    for (i in 0...count) {
      var fnx = norms[i].x * sign;
      var fny = norms[i].y * sign;
      if (fnx == 0 && fny == 0) continue;
      var dot = fnx * dx + fny * dy;
      if (dot > best_dot) {
        best_dot = dot;
        best = i;
        out_normal.set(fnx, fny);
      }
    }
    return best;
  }
  /**
   * Clips the segment (`inc0`, `inc1`) against the half-plane `dot(n, p) - c <= 0`, storing the results back into `inc0`/`inc1`.
   * @return The number of points remaining after the clip.
   */
  static function clip_segment(nx:Float, ny:Float, c:Float):Int {
    var d0 = nx * inc0.x + ny * inc0.y - c;
    var d1 = nx * inc1.x + ny * inc1.y - c;
    if (d0 <= 0 && d1 <= 0) return 2;
    if (d0 > 0 && d1 > 0) return 0;
    // One point is inside and one is out - replace the outside point with the intersection
    var alpha = d0 / (d0 - d1);
    var ix = inc0.x + alpha * (inc1.x - inc0.x);
    var iy = inc0.y + alpha * (inc1.y - inc0.y);
    if (d0 > 0) inc0.set(ix, iy);
    else inc1.set(ix, iy);
    return 2;
  }

  /**
   * Test a Rect and a Circle for a Collision.
   * @param r
   * @param c
   * @param flip
   * @return Null<CollisionData>
   */
  public static function rect_and_circle(r:Rect, c:Circle, flip:Bool = false):Null<CollisionData> {
    if (r.transformed_rect != null && r.rotation != 0) {
      var col = circle_and_polygon(c, r.transformed_rect, !flip);

      if (col == null) return null;

      // collisions used the transformed rect, set the collision data's shape back
      // to the original rect
      if (!flip) col.sa = r;
      else col.sb = r;

      return col;
    }

    // Vector from A to B
    var nx = flip ? r.x - c.x : c.x - r.x;
    var ny = flip ? r.y - c.y : c.y - r.y;
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

    // Contact point is the closest point on the Rect to the Circle (or the Circle's center, if it's inside the Rect)
    if (inside) col.add_contact(c.x, c.y);
    else if (flip) col.add_contact(r.x - cx, r.y - cy);
    else col.add_contact(r.x + cx, r.y + cy);

    return col;
  }

  public static function rect_and_polygon(r:Rect, p:Polygon, flip:Bool = false):Null<CollisionData> {
    var col:CollisionData = null;
    if (r.transformed_rect != null) {
      col = polygon_and_polygon(r.transformed_rect, p, flip);
    }
    else {
      var tr = Polygon.get_from_rect(r);
      @:privateAccess
      tr.set_parent(r.parent);
      col = polygon_and_polygon(tr, p, flip);
      tr.put();
    }

    if (col == null) return null;

    // collisions were done with a polygon derrived from the provided rect
    // so we need to set our collision data shape back to the original rectangle
    if (flip) col.sb = r;
    else col.sa = r;

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
      distance = (c_pos - p.vertices[i]).length_sq;

      if (distance < testDistance) {
        testDistance = distance;
        closest.set(p.vertices[i].x, p.vertices[i].y);
      }
    }

    var normal = (closest - c_pos).normal;

    // Project the polygon's points
    var test:Float = 0;
    var min1 = normal.dot(p.vertices[0]);
    var max1 = min1;

    for (j in 1...p.count) {
      test = normal.dot(p.vertices[j]);
      if (test < min1) min1 = test;
      if (test > max1) max1 = test;
    }

    // Project the circle
    var max2 = c_rad;
    var min2 = -c_rad;
    var offset = normal.dot(-c_pos);

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
      min1 = normal.dot(p.vertices[0]);
      max1 = min1;

      // Project all other points
      for (j in 1...p.count) {
        test = normal.dot(p.vertices[j]);
        if (test < min1) min1 = test;
        if (test > max1) max1 = test;
      }

      // Project the circle
      max2 = c_rad;
      min2 = -c_rad;

      // Offset points
      offset = normal.dot(-c_pos);
      min1 += offset;
      max1 += offset;

      test1 = min1 - max2;
      test2 = min2 - max1;

      // Perform another test
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
      col.normal.negate();
    }

    // Contact point is halfway into the penetration, along the normal from the Circle's center towards the Polygon
    var dir = flip ? -1 : 1;
    var cd = c_rad - col.overlap * 0.5;
    col.add_contact(c_pos.x + col.normal.x * dir * cd, c_pos.y + col.normal.y * dir * cd);

    return col;
  }

  // Results of the last `check_polygons()` call - the axis of least penetration
  static var sat_overlap:Float = 0;
  static var sat_nx:Float = 0;
  static var sat_ny:Float = 0;
  /**
   * Projects both Polygons onto each of `polygon1`'s face normals, looking for a separating axis.
   * @return `false` if a separating axis was found (the Polygons don't overlap). Otherwise `true`, with the axis of least penetration stored in
   * `sat_overlap`, `sat_nx`, and `sat_ny` (the normal as stored in `polygon1.normals`, which points into `polygon1`).
   */
  static function check_polygons(polygon1:Polygon, polygon2:Polygon):Bool {
    var verts1 = polygon1.vertices;
    var norms1 = polygon1.normals;
    var verts2 = polygon2.vertices;
    var count1 = polygon1.count;
    var count2 = polygon2.count;
    var closest = Math.POSITIVE_INFINITY;

    for (i in 0...count1) {
      var nx = norms1[i].x;
      var ny = norms1[i].y;

      // project polygon1
      var v = verts1[0];
      var min1 = nx * v.x + ny * v.y;
      var max1 = min1;
      for (j in 1...count1) {
        v = verts1[j];
        var t = nx * v.x + ny * v.y;
        if (t < min1) min1 = t;
        if (t > max1) max1 = t;
      }

      // project polygon2
      v = verts2[0];
      var min2 = nx * v.x + ny * v.y;
      var max2 = min2;
      for (j in 1...count2) {
        v = verts2[j];
        var t = nx * v.x + ny * v.y;
        if (t < min2) min2 = t;
        if (t > max2) max2 = t;
      }

      // Separating axis found - no collision
      if (min1 - max2 > 0 || min2 - max1 > 0) return false;

      var overlap = max2 - min1;
      if (overlap < 0) overlap = -overlap;
      if (overlap < closest) {
        closest = overlap;
        sat_nx = nx;
        sat_ny = ny;
      }
    }

    sat_overlap = closest;
    return true;
  }
}
