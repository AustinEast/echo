package suite;

import suite.Test.*;
import echo.Body;
import echo.Echo;
import echo.World;
import echo.shape.Polygon;
import echo.util.Decompose;
import echo.math.Vector2;

class DecomposeTest {
  // An "L" - one reflex vertex. 40x10 horizontal bar + 10x30 vertical bar = 700 units of area
  static var L:Array<Vector2> = [
    new Vector2(0, 0),
    new Vector2(40, 0),
    new Vector2(40, 10),
    new Vector2(10, 10),
    new Vector2(10, 40),
    new Vector2(0, 40)
  ];
  // A "+" centered on its origin - four reflex vertices, 2000 units of area
  static var PLUS:Array<Vector2> = [
    new Vector2(-10, -30),
    new Vector2(10, -30),
    new Vector2(10, -10),
    new Vector2(30, -10),
    new Vector2(30, 10),
    new Vector2(10, 10),
    new Vector2(10, 30),
    new Vector2(-10, 30),
    new Vector2(-10, 10),
    new Vector2(-30, 10),
    new Vector2(-30, -10),
    new Vector2(-10, -10)
  ];

  public static function run() {
    test_helpers();
    test_convex_input();
    test_concave_input();
    test_winding();
    test_polygons();
    test_body();
    test_collisions();
  }

  static function star(points:Int, outer:Float, inner:Float):Array<Vector2> {
    var verts = [];
    var step = Math.PI / points;
    for (i in 0...points * 2) {
      var r = i % 2 == 0 ? outer : inner;
      verts.push(new Vector2(Math.cos(i * step) * r, Math.sin(i * step) * r));
    }
    return verts;
  }

  static function area(vertices:Array<Vector2>):Float return Math.abs(Decompose.signed_area(vertices));

  static function total_area(pieces:Array<Array<Vector2>>):Float {
    var sum = 0.;
    for (piece in pieces) sum += area(piece);
    return sum;
  }

  static function all_convex(pieces:Array<Array<Vector2>>):Bool {
    for (piece in pieces) if (!Decompose.is_convex(piece)) return false;
    return true;
  }
  /**
   * Even-odd point-in-polygon test, so the pieces can be checked against the polygon they came from.
   */
  static function contains(vertices:Array<Vector2>, p:Vector2):Bool {
    var inside = false;
    var n = vertices.length;
    var j = n - 1;
    for (i in 0...n) {
      var a = vertices[i];
      var b = vertices[j];
      if ((a.y > p.y) != (b.y > p.y) && p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x) inside = !inside;
      j = i;
    }
    return inside;
  }

  /**
   * Returns the amount of sample points where the pieces don't line up with the polygon they came from - a point inside
   * the polygon has to be covered by exactly one piece, and a point outside it by none. Catches pieces that overlap
   * each other, leave a gap, or spill over a concave notch.
   */
  static function tiling_errors(vertices:Array<Vector2>, pieces:Array<Array<Vector2>>, samples:Int = 64):Int {
    var min_x = vertices[0].x, min_y = vertices[0].y, max_x = vertices[0].x, max_y = vertices[0].y;
    for (v in vertices) {
      if (v.x < min_x) min_x = v.x;
      if (v.y < min_y) min_y = v.y;
      if (v.x > max_x) max_x = v.x;
      if (v.y > max_y) max_y = v.y;
    }

    var step_x = (max_x - min_x) / samples;
    var step_y = (max_y - min_y) / samples;
    var errors = 0;
    for (ix in 0...samples) {
      for (iy in 0...samples) {
        // Offset the samples by an arbitrary fraction of a step so they don't land on the polygon's edges
        var p = new Vector2(min_x + (ix + 0.3137) * step_x, min_y + (iy + 0.5913) * step_y);
        var covered = 0;
        for (piece in pieces) if (contains(piece, p)) covered++;
        if (covered != (contains(vertices, p) ? 1 : 0)) errors++;
      }
    }
    return errors;
  }

  static function test_helpers() {
    section('decompose: helpers');
    var square = [new Vector2(0, 0), new Vector2(10, 0), new Vector2(10, 10), new Vector2(0, 10)];
    check('signed_area of a square', approx(Decompose.signed_area(square), 100), '${Decompose.signed_area(square)}');
    square.reverse();
    check('signed_area flips sign with the winding order', approx(Decompose.signed_area(square), -100), '${Decompose.signed_area(square)}');
    check('centroid of a square is its center', Decompose.centroid(square).x == 5 && Decompose.centroid(square).y == 5, '${Decompose.centroid(square)}');

    check('a square is convex', Decompose.is_convex(square));
    check('an L is not convex', !Decompose.is_convex(L));
    check('a plus is not convex', !Decompose.is_convex(PLUS));

    check('a square is simple', Decompose.is_simple(square));
    check('an L is simple', Decompose.is_simple(L));
    check('a bowtie is not simple', !Decompose.is_simple([new Vector2(0, 0), new Vector2(10, 10), new Vector2(10, 0), new Vector2(0, 10)]));

    var collinear = [new Vector2(0, 0), new Vector2(5, 0), new Vector2(10, 0), new Vector2(10, 10), new Vector2(0, 10)];
    check('remove_collinear drops the extra vertex', Decompose.remove_collinear(collinear) == 1 && collinear.length == 4, '${collinear.length}');

    var dupes = [new Vector2(0, 0), new Vector2(10, 0), new Vector2(10, 0), new Vector2(10, 10), new Vector2(0, 10)];
    check('remove_duplicates drops the repeated vertex', Decompose.remove_duplicates(dupes) == 1 && dupes.length == 4, '${dupes.length}');
  }

  static function test_convex_input() {
    section('decompose: convex input');
    var square = [new Vector2(0, 0), new Vector2(10, 0), new Vector2(10, 10), new Vector2(0, 10)];
    var pieces = Decompose.convex(square);
    check('a convex polygon comes back as one piece', pieces.length == 1, '${pieces.length}');
    check('the piece keeps every vertex', pieces.length == 1 && pieces[0].length == 4);
    check('the input vertices are left alone', square.length == 4 && square[0].x == 0 && square[0].y == 0);

    var before = 0.;
    for (v in pieces[0]) before += v.x + v.y;
    for (v in square) {
      v.x = 999;
      v.y = 999;
    }
    var after = 0.;
    for (v in pieces[0]) after += v.x + v.y;
    check('the pieces do not alias the input vertices', before == after, '$before vs $after');

    check('a triangle comes back as one piece', Decompose.convex([new Vector2(0, 0), new Vector2(10, 0), new Vector2(0, 10)]).length == 1);
    check('a degenerate polygon comes back empty', Decompose.convex([new Vector2(0, 0), new Vector2(10, 0)]).length == 0);
  }

  static function test_concave_input() {
    section('decompose: concave input');

    var pieces = Decompose.convex(L);
    check('an L splits into 2 pieces', pieces.length == 2, '${pieces.length}');
    check('the L pieces are all convex', all_convex(pieces));
    check('the L pieces add up to the original area', approx(total_area(pieces), 700, 1e-6), '${total_area(pieces)}');
    check('the L pieces tile the original polygon', tiling_errors(L, pieces) == 0, '${tiling_errors(L, pieces)}');

    pieces = Decompose.convex(PLUS);
    check('a plus splits into one piece per reflex vertex at most', pieces.length > 1 && pieces.length <= 5, '${pieces.length}');
    check('the plus pieces are all convex', all_convex(pieces));
    check('the plus pieces add up to the original area', approx(total_area(pieces), 2000, 1e-6), '${total_area(pieces)}');
    check('the plus pieces tile the original polygon', tiling_errors(PLUS, pieces) == 0, '${tiling_errors(PLUS, pieces)}');

    var s = star(5, 40, 16);
    pieces = Decompose.convex(s);
    check('a 5 point star splits into one piece per reflex vertex at most', pieces.length > 1 && pieces.length <= 6, '${pieces.length}');
    check('the star pieces are all convex', all_convex(pieces));
    check('the star pieces add up to the original area', approx(total_area(pieces), area(s), 1e-6), '${total_area(pieces)} vs ${area(s)}');
    check('the star pieces tile the original polygon', tiling_errors(s, pieces) == 0, '${tiling_errors(s, pieces)}');

    // A notch that has to be cut with a steiner point (no vertex is visible across it)
    var notch = [
      new Vector2(0, 0),
      new Vector2(40, 0),
      new Vector2(40, 40),
      new Vector2(30, 40),
      new Vector2(20, 20),
      new Vector2(10, 40),
      new Vector2(0, 40)
    ];
    pieces = Decompose.convex(notch);
    check('a steiner point notch is decomposed', pieces.length > 1 && all_convex(pieces), '${pieces.length}');
    check('the notch pieces add up to the original area', approx(total_area(pieces), area(notch), 1e-6), '${total_area(pieces)} vs ${area(notch)}');
    check('the notch pieces tile the original polygon', tiling_errors(notch, pieces) == 0, '${tiling_errors(notch, pieces)}');

    check('max_pieces caps the amount of pieces', Decompose.convex(PLUS, 1e-10, 2).length == 2);
  }

  static function test_winding() {
    section('decompose: winding order');
    var ccw = L.copy();
    if (Decompose.signed_area(ccw) < 0) ccw.reverse();
    var cw = ccw.copy();
    cw.reverse();

    var matched = true;
    for (piece in Decompose.convex(ccw)) if (Decompose.signed_area(piece) < 0) matched = false;
    check('counter-clockwise input produces counter-clockwise pieces', matched);

    matched = true;
    for (piece in Decompose.convex(cw)) if (Decompose.signed_area(piece) > 0) matched = false;
    check('clockwise input produces clockwise pieces', matched);
  }

  static function test_polygons() {
    section('decompose: polygons');
    var polygons = Polygon.get_from_concave_vertices(0, 0, 0, PLUS);
    check('a plus makes a Polygon per piece', polygons.length == Decompose.convex(PLUS).length, '${polygons.length}');

    var volume = 0.;
    for (p in polygons) volume += p.volume();
    check('the Polygons\' volume matches the plus\' area', approx(volume, 2000, 1e-6), '$volume');

    // Each piece is positioned at its own centroid, but together they cover the same space as the source vertices
    var min_x = 1e9, min_y = 1e9, max_x = -1e9, max_y = -1e9;
    for (p in polygons) {
      var b = p.bounds();
      if (b.min_x < min_x) min_x = b.min_x;
      if (b.min_y < min_y) min_y = b.min_y;
      if (b.max_x > max_x) max_x = b.max_x;
      if (b.max_y > max_y) max_y = b.max_y;
      b.put();
    }
    check('the Polygons cover the same bounds as the vertices', approx(min_x, -30) && approx(min_y, -30) && approx(max_x, 30) && approx(max_y, 30),
      '$min_x, $min_y, $max_x, $max_y');

    // Offset, rotation and scale have to be applied around the vertex set's origin, not each piece's own centroid
    var rotated = Polygon.get_from_concave_vertices(100, 50, 90, PLUS, 2, 2);
    min_x = min_y = 1e9;
    max_x = max_y = -1e9;
    volume = 0;
    for (p in rotated) {
      volume += p.volume();
      var b = p.bounds();
      if (b.min_x < min_x) min_x = b.min_x;
      if (b.min_y < min_y) min_y = b.min_y;
      if (b.max_x > max_x) max_x = b.max_x;
      if (b.max_y > max_y) max_y = b.max_y;
      b.put();
    }
    check('offset, rotation and scale keep the pieces together', approx(min_x, 40) && approx(min_y, -10) && approx(max_x, 160) && approx(max_y, 110),
      '$min_x, $min_y, $max_x, $max_y');
    check('scaling scales the volume', approx(volume, 2000 * 4, 1e-6), '$volume');

    for (p in polygons) p.put();
    for (p in rotated) p.put();
  }

  static function test_body() {
    section('decompose: bodies');
    var body = new Body({
      x: 0,
      y: 0,
      shape: {
        type: POLYGON,
        vertices: PLUS,
        decompose: true
      }
    });
    check('the Body gets a Shape per piece', body.shapes.length == Decompose.convex(PLUS).length, '${body.shapes.length}');
    check('the Body\'s mass comes from the whole plus', approx(body.mass, 2000), '${body.mass}');

    // The corners of the plus' bounding box are in the notches, so no Shape should contain them
    var in_notch = false;
    for (shape in body.shapes) if (shape.contains(new Vector2(-29, -29)) || shape.contains(new Vector2(29, 29))) in_notch = true;
    check('the notches are empty', !in_notch);

    var contained = 0;
    for (shape in body.shapes) if (shape.contains(new Vector2(0, 0))) contained++;
    check('the middle of the plus is solid', contained > 0);

    var arms = 0;
    for (shape in body.shapes) {
      if (shape.contains(new Vector2(25, 0))) arms++;
      if (shape.contains(new Vector2(-25, 0))) arms++;
      if (shape.contains(new Vector2(0, 25))) arms++;
      if (shape.contains(new Vector2(0, -25))) arms++;
    }
    check('all four arms are solid', arms == 4, '$arms');

    var b = body.bounds();
    check('the Body\'s bounds match the plus', approx(b.min_x, -30) && approx(b.min_y, -30) && approx(b.max_x, 30) && approx(b.max_y, 30), '$b');
    b.put();

    // Without the flag, the concave vertices are used as-is (a single, incorrect, convex Shape)
    var raw = new Body({shape: {type: POLYGON, vertices: PLUS}});
    check('decompose is opt-in', raw.shapes.length == 1, '${raw.shapes.length}');

    body.dispose();
    raw.dispose();
  }

  static function test_collisions() {
    section('decompose: collisions');
    var world = Echo.start({width: 400, height: 400, gravity_y: 0});
    var concave = new Body({
      x: 200,
      y: 200,
      mass: STATIC,
      shape: {
        type: POLYGON,
        vertices: PLUS,
        decompose: true
      }
    });
    // Sits in the plus' notch - overlaps the Body's bounds, but not the Body itself
    var in_notch = new Body({x: 225, y: 225, shape: {type: CIRCLE, radius: 4}});
    // Sits on the plus' right arm
    var on_arm = new Body({x: 225, y: 200, shape: {type: CIRCLE, radius: 4}});
    world.add(concave);
    world.add(in_notch);
    world.add(on_arm);

    var hit_in_notch = false;
    var hit_on_arm = false;
    world.listen(concave, in_notch, {enter: (a, b, c) -> hit_in_notch = true, separate: false});
    world.listen(concave, on_arm, {enter: (a, b, c) -> hit_on_arm = true, separate: false});
    world.step(1 / 60);

    check('a Body in the notch does not collide', !hit_in_notch);
    check('a Body on an arm collides', hit_on_arm);

    world.dispose();
  }
}
