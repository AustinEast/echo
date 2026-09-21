package echo.util;

import echo.math.Vector2;
/**
 * Convex Decomposition utilities.
 *
 * Echo's collision detection is built on SAT, which only works with convex Shapes. `Decompose.convex()` splits a concave
 * (but non self-intersecting) set of vertices into a set of convex ones, which can then be attached to a single `Body`
 * as multiple `Polygon` Shapes.
 *
 * Most of the time this doesn't need to be called directly - set `decompose: true` on a Polygon's `ShapeOptions`
 * (or use `Polygon.get_from_concave_vertices()`) and the decomposition is done for you.
 *
 * The decomposition uses Mark Bayazit's algorithm, which produces a low (but not guaranteed minimal) amount of pieces
 * without adding many extra vertices.
 */
class Decompose {
  /**
   * The maximum amount of times `convex()` will recursively split a polygon before giving up. Acts as a safety net
   * against pathological input.
   */
  public static var max_depth:Int = 100;
  /**
   * Decomposes a set of vertices into a set of convex vertices.
   *
   * The input is expected to describe a **simple** polygon - one whose edges don't cross each other (use `is_simple()`
   * to check) and which has no holes. Self-intersecting input will produce garbage pieces rather than an error.
   *
   * The winding order of the input is preserved in the returned pieces. Neither the input Array nor its `Vector2`s are
   * modified - every returned vertex is a new `Vector2`.
   * @param vertices The vertices to decompose.
   * @param tolerance Values below this are treated as zero when discarding duplicate/collinear vertices and when
   * testing lines for being parallel.
   * @param max_pieces The maximum amount of pieces to split the polygon into. Once this is reached, the remaining
   * piece is returned as-is (and may still be concave). Set to `0` for no limit.
   * @return An Array of convex vertex Arrays. Returns an empty Array if the input has less than 3 usable vertices.
   */
  public static function convex(vertices:Array<Vector2>, tolerance:Float = 1e-10, max_pieces:Int = 0):Array<Array<Vector2>> {
    var poly = [for (v in vertices) new Vector2(v.x, v.y)];
    remove_duplicates(poly, tolerance);
    remove_collinear(poly, tolerance);
    if (poly.length < 3) return [];

    // The algorithm expects a counter-clockwise winding - flip it back afterwards if the input was clockwise
    var flipped = signed_area(poly) < 0;
    if (flipped) poly.reverse();

    var result:Array<Array<Vector2>> = [];
    if (is_convex(poly)) result.push(poly);
    else quick_decomp(poly, result, tolerance, max_pieces, 0);

    var pieces:Array<Array<Vector2>> = [];
    for (piece in result) {
      remove_collinear(piece, tolerance);
      if (piece.length < 3) continue;
      if (flipped) piece.reverse();
      pieces.push(piece);
    }
    return pieces;
  }
  /**
   * Returns the signed area of the vertices. The sign describes the winding order - it is positive if the vertices wind
   * counter-clockwise (in a Y-up space), negative if they wind clockwise.
   *
   * Note that Echo's Y axis points down, so a positive area looks *clockwise* on screen.
   */
  public static function signed_area(vertices:Array<Vector2>):Float {
    var n = vertices.length;
    if (n < 3) return 0;

    var sum = 0.;
    var v = vertices[n - 1];
    for (i in 0...n) {
      var vi = vertices[i];
      sum += v.x * vi.y - vi.x * v.y;
      v = vi;
    }
    return sum * 0.5;
  }
  /**
   * Returns the centroid (center of mass) of the vertices. Falls back to the average of the vertices if they describe
   * no area.
   */
  public static function centroid(vertices:Array<Vector2>):Vector2 {
    var n = vertices.length;
    if (n == 0) return new Vector2(0, 0);

    var ca = 0.;
    var cx = 0.;
    var cy = 0.;
    var v = vertices[n - 1];
    for (i in 0...n) {
      var vi = vertices[i];
      var a = v.x * vi.y - vi.x * v.y;
      cx += (v.x + vi.x) * a;
      cy += (v.y + vi.y) * a;
      ca += a;
      v = vi;
    }

    // Degenerate (zero area) vertices - average them instead
    if (Math.abs(ca) < 1e-12) {
      cx = cy = 0;
      for (i in 0...n) {
        cx += vertices[i].x;
        cy += vertices[i].y;
      }
      return new Vector2(cx / n, cy / n);
    }

    ca *= 3;
    return new Vector2(cx / ca, cy / ca);
  }
  /**
   * Returns `true` if the vertices describe a convex polygon (in either winding order).
   */
  public static function is_convex(vertices:Array<Vector2>):Bool {
    var n = vertices.length;
    if (n < 4) return true;

    var positive = false;
    var negative = false;
    for (i in 0...n) {
      var a = area(at(vertices, i - 1), vertices[i], at(vertices, i + 1));
      if (a > 0) positive = true;
      else if (a < 0) negative = true;
      if (positive && negative) return false;
    }
    return true;
  }
  /**
   * Returns `true` if the vertices describe a simple polygon - one where no two edges cross each other.
   *
   * `convex()` expects simple input, so this is useful for validating vertices that come from an editor or a file.
   */
  public static function is_simple(vertices:Array<Vector2>):Bool {
    var n = vertices.length;
    for (i in 0...n - 1) {
      for (j in 0...i - 1) if (segments_intersect(vertices[i], vertices[i + 1], vertices[j], vertices[j + 1])) return false;
    }
    // Check the closing edge against every edge it doesn't touch
    for (i in 1...n - 2) if (segments_intersect(vertices[0], vertices[n - 1], vertices[i], vertices[i + 1])) return false;

    return true;
  }
  /**
   * Returns `true` if the vertex at `index` is reflex (ie it points into the polygon, making it concave).
   *
   * Expects a counter-clockwise winding order.
   */
  public static inline function is_reflex(vertices:Array<Vector2>, index:Int):Bool {
    return area(at(vertices, index - 1), at(vertices, index), at(vertices, index + 1)) < 0;
  }
  /**
   * Removes any vertices that sit on top of their neighbor (in place).
   * @return The amount of vertices removed.
   */
  public static function remove_duplicates(vertices:Array<Vector2>, tolerance:Float = 1e-10):Int {
    var removed = 0;
    var i = vertices.length - 1;
    while (i >= 0 && vertices.length > 1) {
      var a = vertices[i];
      var b = at(vertices, i - 1);
      if (sqdist(a, b) <= tolerance * tolerance) {
        vertices.splice(i, 1);
        removed++;
      }
      i--;
    }
    return removed;
  }
  /**
   * Removes any vertices that sit on the line between their neighbors (in place), as they add nothing to the polygon's
   * form but cost time during collision checks.
   * @return The amount of vertices removed.
   */
  public static function remove_collinear(vertices:Array<Vector2>, tolerance:Float = 1e-10):Int {
    var removed = 0;
    var i = vertices.length - 1;
    while (i >= 0 && vertices.length > 3) {
      if (Math.abs(area(at(vertices, i - 1), vertices[i], at(vertices, i + 1))) <= tolerance) {
        vertices.splice(i, 1);
        removed++;
      }
      i--;
    }
    return removed;
  }

  // Bayazit's algorithm - recursively cuts the polygon at its first reflex vertex until nothing concave is left
  static function quick_decomp(poly:Array<Vector2>, result:Array<Array<Vector2>>, tolerance:Float, max_pieces:Int, depth:Int):Void {
    var n = poly.length;
    if (n < 3) return;
    if (depth > max_depth || (max_pieces > 0 && result.length >= max_pieces - 1)) {
      result.push(poly);
      return;
    }

    for (i in 0...n) {
      if (!is_reflex(poly, i)) continue;

      var lower_int = new Vector2(0, 0);
      var upper_int = new Vector2(0, 0);
      var lower_dist = Math.POSITIVE_INFINITY;
      var upper_dist = Math.POSITIVE_INFINITY;
      var lower_index = 0;
      var upper_index = 0;

      // Extend both edges of the reflex vertex until they hit another edge, keeping the closest hit on each side
      for (j in 0...n) {
        if (left(at(poly, i - 1), at(poly, i), at(poly, j)) && right_on(at(poly, i - 1), at(poly, i), at(poly, j - 1))) {
          var p = line_intersection(at(poly, i - 1), at(poly, i), at(poly, j), at(poly, j - 1), tolerance);
          if (p != null && right(at(poly, i + 1), at(poly, i), p)) {
            var d = sqdist(poly[i], p);
            if (d < lower_dist) {
              lower_dist = d;
              lower_int = p;
              lower_index = j;
            }
          }
        }
        if (left(at(poly, i + 1), at(poly, i), at(poly, j + 1)) && right_on(at(poly, i + 1), at(poly, i), at(poly, j))) {
          var p = line_intersection(at(poly, i + 1), at(poly, i), at(poly, j), at(poly, j + 1), tolerance);
          if (p != null && left(at(poly, i - 1), at(poly, i), p)) {
            var d = sqdist(poly[i], p);
            if (d < upper_dist) {
              upper_dist = d;
              upper_int = p;
              upper_index = j;
            }
          }
        }
      }

      // Malformed (likely self-intersecting) input - nothing was found to cut against
      if (lower_dist == Math.POSITIVE_INFINITY || upper_dist == Math.POSITIVE_INFINITY) {
        result.push(poly);
        return;
      }

      var lower_poly:Array<Vector2> = [];
      var upper_poly:Array<Vector2> = [];

      if (lower_index == (upper_index + 1) % n) {
        // The two hits are on the same edge - cut to a new vertex halfway between them
        var px = (lower_int.x + upper_int.x) * 0.5;
        var py = (lower_int.y + upper_int.y) * 0.5;
        if (i < upper_index) {
          append(lower_poly, poly, i, upper_index + 1);
          lower_poly.push(new Vector2(px, py));
          upper_poly.push(new Vector2(px, py));
          if (lower_index != 0) append(upper_poly, poly, lower_index, n);
          append(upper_poly, poly, 0, i + 1);
        }
        else {
          if (i != 0) append(lower_poly, poly, i, n);
          append(lower_poly, poly, 0, upper_index + 1);
          lower_poly.push(new Vector2(px, py));
          upper_poly.push(new Vector2(px, py));
          append(upper_poly, poly, lower_index, i + 1);
        }
      }
      else {
        // Cut to the closest vertex that sits between the two hits and can be seen from the reflex vertex
        if (lower_index > upper_index) upper_index += n;

        var closest_index = -1;
        var closest_dist = Math.POSITIVE_INFINITY;
        var visible_only = true;
        while (closest_index == -1) {
          for (j in lower_index...upper_index + 1) {
            if (left_on(at(poly, i - 1), at(poly, i), at(poly, j)) && right_on(at(poly, i + 1), at(poly, i), at(poly, j))) {
              var d = sqdist(at(poly, i), at(poly, j));
              if (d < closest_dist && (!visible_only || can_see(poly, i, j % n))) {
                closest_dist = d;
                closest_index = j % n;
              }
            }
          }
          // Nothing was visible - fall back to the closest candidate, then give up on this piece
          if (closest_index == -1) {
            if (!visible_only) {
              result.push(poly);
              return;
            }
            visible_only = false;
          }
        }

        if (i < closest_index) {
          append(lower_poly, poly, i, closest_index + 1);
          if (closest_index != 0) append(upper_poly, poly, closest_index, n);
          append(upper_poly, poly, 0, i + 1);
        }
        else {
          if (i != 0) append(lower_poly, poly, i, n);
          append(lower_poly, poly, 0, closest_index + 1);
          append(upper_poly, poly, closest_index, i + 1);
        }
      }

      // Solve the smallest piece first, so a `max_pieces` cutoff leaves the largest piece intact
      if (lower_poly.length < upper_poly.length) {
        quick_decomp(lower_poly, result, tolerance, max_pieces, depth + 1);
        quick_decomp(upper_poly, result, tolerance, max_pieces, depth + 1);
      }
      else {
        quick_decomp(upper_poly, result, tolerance, max_pieces, depth + 1);
        quick_decomp(lower_poly, result, tolerance, max_pieces, depth + 1);
      }
      return;
    }

    result.push(poly);
  }
  /**
   * Returns `true` if a line drawn between the vertices at `a` and `b` stays clear of every edge of the polygon.
   */
  static function can_see(poly:Array<Vector2>, a:Int, b:Int):Bool {
    var n = poly.length;
    for (i in 0...n) {
      var next = (i + 1) % n;
      // Skip the edges that touch either vertex - they always "intersect" at the shared point
      if (i == a || i == b || next == a || next == b) continue;
      if (segments_intersect(poly[a], poly[b], poly[i], poly[next])) return false;
    }
    return true;
  }

  static inline function append(dest:Array<Vector2>, src:Array<Vector2>, from:Int, to:Int) {
    for (i in from...to) dest.push(new Vector2(src[i].x, src[i].y));
  }
  /**
   * Twice the signed area of the triangle `abc`. Positive if `c` is to the left of the line `ab`.
   */
  static inline function area(a:Vector2, b:Vector2, c:Vector2):Float {
    return (b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y);
  }

  static inline function left(a:Vector2, b:Vector2, c:Vector2):Bool return area(a, b, c) > 0;

  static inline function left_on(a:Vector2, b:Vector2, c:Vector2):Bool return area(a, b, c) >= 0;

  static inline function right(a:Vector2, b:Vector2, c:Vector2):Bool return area(a, b, c) < 0;

  static inline function right_on(a:Vector2, b:Vector2, c:Vector2):Bool return area(a, b, c) <= 0;

  static inline function sqdist(a:Vector2, b:Vector2):Float {
    var dx = b.x - a.x;
    var dy = b.y - a.y;
    return dx * dx + dy * dy;
  }
  /**
   * Indexes into the vertices, wrapping around at both ends.
   */
  static inline function at(vertices:Array<Vector2>, index:Int):Vector2 {
    var n = vertices.length;
    var i = index % n;
    return vertices[i < 0 ? i + n : i];
  }
  /**
   * The point where the infinite lines through `a1a2` and `b1b2` cross, or `null` if they are parallel.
   */
  static function line_intersection(a1:Vector2, a2:Vector2, b1:Vector2, b2:Vector2, tolerance:Float):Null<Vector2> {
    var a = a2.y - a1.y;
    var b = a1.x - a2.x;
    var c = a * a1.x + b * a1.y;
    var a_ = b2.y - b1.y;
    var b_ = b1.x - b2.x;
    var c_ = a_ * b1.x + b_ * b1.y;

    var det = a * b_ - a_ * b;
    if (Math.abs(det) <= tolerance) return null;

    return new Vector2((b_ * c - b * c_) / det, (a * c_ - a_ * c) / det);
  }
  /**
   * Returns `true` if the line segments `p1p2` and `q1q2` cross.
   */
  static function segments_intersect(p1:Vector2, p2:Vector2, q1:Vector2, q2:Vector2):Bool {
    var dx = p2.x - p1.x;
    var dy = p2.y - p1.y;
    var da = q2.x - q1.x;
    var db = q2.y - q1.y;

    var det = da * dy - db * dx;
    if (det == 0) return false; // the segments are parallel

    var s = (dx * (q1.y - p1.y) + dy * (p1.x - q1.x)) / det;
    var t = (da * (p1.y - q1.y) + db * (q1.x - p1.x)) / -det;

    return s >= 0 && s <= 1 && t >= 0 && t <= 1;
  }
}
