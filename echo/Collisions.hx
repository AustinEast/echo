package echo;

import echo.Body;
import echo.Listener;
import echo.data.Data;
import echo.util.AABB;
import echo.util.QuadTree;
/**
 * Class containing methods for performing Collisions on a World
 */
class Collisions {
  // Bit flags used in `Body.collision_mask` to mark which of a Listener's Body groups a Body belongs to during a broadphase query
  static inline var IN_A = 1;
  static inline var IN_B = 2;

  /**
   * How much a dynamic Body's bounds are padded (as a fraction of their size) when stored in the World's QuadTree.
   *
   * A Body only needs to be re-inserted into the QuadTree once it moves outside of its padded bounds, so Bodies that are resting or jittering in place
   * skip the QuadTree update entirely. Larger values mean fewer updates but more broadphase candidates. Set to `0` to store exact bounds.
   */
  public static var quadtree_padding:Float = 0.1;

  static var qr:Array<QuadTreeData> = [];
  static var sqr:Array<QuadTreeData> = [];
  static var tight_bounds:AABB = AABB.get();
  static var query_bounds:AABB = AABB.get();
  /**
   * Updates the World's dynamic QuadTree with any Bodies that have moved.
   */
  public static function update_quadtree(world:World) {
    inline function update_body(b:Body) {
      if (!b.disposed) {
        b.collided = false;
        for (shape in b.shapes) {
          shape.collided = false;
        }
        if (b.active && b.is_dynamic() && b.dirty && b.shapes.length > 0) {
          var stored = b.quadtree_data.bounds;
          b.bounds(tight_bounds);
          if (stored == null) {
            stored = b.quadtree_data.bounds = AABB.get();
            pad_bounds(stored, tight_bounds);
            world.quadtree.insert(b.quadtree_data);
          }
          // Only re-insert the Body once it has moved outside of the padded bounds it was stored with
          else if (!contains_bounds(stored, tight_bounds)) {
            // Remove the Body from the QuadTree while its data still holds the bounds it was inserted with, so the search can be pruned
            world.quadtree.remove(b.quadtree_data, false, true);
            pad_bounds(stored, tight_bounds);
            world.quadtree.insert(b.quadtree_data);
          }
          b.dirty = false;
        }
      }
    }

    world.for_each(b -> update_body(b));
    world.quadtree.shake();
  }

  static inline function contains_bounds(outer:AABB, inner:AABB):Bool {
    return outer.min_x <= inner.min_x && outer.max_x >= inner.max_x && outer.min_y <= inner.min_y && outer.max_y >= inner.max_y;
  }

  static inline function pad_bounds(target:AABB, source:AABB) {
    var px = source.width * quadtree_padding;
    var py = source.height * quadtree_padding;
    target.set_from_min_max(source.min_x - px, source.min_y - py, source.max_x + px, source.max_y + py);
  }
  /**
   * Queries a World's Listeners for Collisions.
   * @param world The World to query.
   * @param listeners Optional collection of listeners to query. If this is set, the World's listeners will not be queried.
   */
  public static function query(world:World, ?listeners:Listeners) {
    update_quadtree(world);
    // Process the Listeners
    var members = listeners == null ? world.listeners.members : listeners.members;
    for (listener in members) {
      // BroadPhase
      listener.quadtree_results.resize(0);
      switch (listener.a) {
        case Left(ba):
          switch (listener.b) {
            case Left(bb):
              var col = overlap_body_and_body_bounds(ba, bb);
              if (col != null) listener.quadtree_results.push(col);
            case Right(ab):
              overlap_body_and_bodies_bounds(ba, ab, world, listener.quadtree_results);
          }
        case Right(aa):
          switch (listener.b) {
            case Left(bb):
              overlap_body_and_bodies_bounds(bb, aa, world, listener.quadtree_results);
            case Right(ab):
              overlap_bodies_and_bodies_bounds(aa, ab, world, listener.quadtree_results);
          }
      }
      // Narrow Phase
      for (collision in listener.last_collisions) collision.put();
      listener.last_collisions.resize(listener.collisions.length);
      for (i in 0...listener.collisions.length) listener.last_collisions[i] = listener.collisions[i];
      listener.collisions.resize(0);
      for (result in listener.quadtree_results) {
        // Filter out disposed bodies (a `condition` callback earlier in this loop may have disposed one)
        if (result.a.disposed || result.b.disposed) {
          result.put();
          continue;
        }

        // Preform the full collision check
        if (result.a.shapes.length == 1 && result.b.shapes.length == 1) {
          var col = result.a.shape.collides(result.b.shape);
          if (col != null) result.data.push(col);
        }
        // If either body has more than one shape, iterate over each shape and perform bounds checks before checking for actual collision
        else {
          var sa = result.a.shapes;
          for (i in 0...sa.length) {
            var sb = result.b.shapes;
            var b1 = sa[i].bounds();
            for (j in 0...sb.length) {
              var b2 = sb[j].bounds();
              if (b1.overlaps(b2)) {
                var col = sa[i].collides(sb[j]);
                if (col != null) result.data.push(col);
              }
              b2.put();
            }
            b1.put();
          }
        }

        // If there was no collision, continue
        if (result.data.length == 0) {
          result.put();
          continue;
        }
        // Check if the collision passes the listener's condition if it has one
        if (listener.condition != null) {
          if (!listener.condition(result.a, result.b, result.data) || result.a.disposed || result.b.disposed) {
            result.put();
            continue;
          }
        }
        for (data in result.data) data.sa.collided = data.sb.collided = true;
        result.a.collided = result.b.collided = true;
        listener.collisions.push(result);
      }
    }
  }
  /**
   * Enacts the Callbacks defined in a World's Listeners
   */
  public static function notify(world:World, ?listeners:Listeners) {
    var members = listeners == null ? world.listeners.members : listeners.members;
    for (listener in members) {
      if (listener.enter != null || listener.stay != null) {
        for (c in listener.collisions) {
          if (!c.a.disposed && !c.b.disposed) {
            inline function find_match() {
              var found = false;
              for (l in listener.last_collisions) {
                if (l.a == c.a && l.b == c.b || l.a == c.b && l.b == c.a) {
                  found = true;
                  break;
                }
              }
              return found;
            }
            if (listener.enter != null && !find_match()) {
              listener.enter(c.a, c.b, c.data);
            }
            else if (listener.stay != null) {
              listener.stay(c.a, c.b, c.data);
            }
          }
        }
      }
      if (listener.exit != null) {
        for (lc in listener.last_collisions) {
          inline function find_match() {
            var found = false;
            for (c in listener.collisions) {
              if (c.a == lc.a && c.b == lc.b || c.a == lc.b && c.b == lc.a) {
                found = true;
                break;
              }
            }
            return found;
          }
          if (!lc.a.disposed && !lc.b.disposed && !find_match()) {
            listener.exit(lc.a, lc.b);
          }
        }
      }
    }
  }
  /**
   * Finds every pair of overlapping Body bounds between the two groups of Bodies, using the World's QuadTrees. Each pair is only reported once, even if the groups overlap (or are the same Array).
   * @param a The first group of Bodies. Each resulting `Collision` has its `a` Body from this group.
   * @param b The second group of Bodies.
   * @param world The World whose QuadTrees are queried.
   * @param results Array that the resulting Collisions are pushed to.
   */
  public static function overlap_bodies_and_bodies_bounds(a:Array<Body>, b:Array<Body>, world:World, results:Array<Collision>) {
    if (a.length == 0 || b.length == 0) return;

    // Mark which group(s) each Body belongs to, so the QuadTree results can be filtered in constant time
    for (body in a) if (body != null) body.collision_mask |= IN_A;
    for (body in b) if (body != null) body.collision_mask |= IN_B;

    for (body in a) {
      if (body == null || body.disposed || body.shapes.length == 0 || !body.active) continue;
      var bounds = stored_bounds(body);
      qr.resize(0);
      world.quadtree.query(bounds, qr);
      collect(body, qr, results);
      // Static Bodies never collide with other static Bodies, so only dynamic Bodies need to query the static QuadTree
      if (body.is_dynamic()) {
        sqr.resize(0);
        world.static_quadtree.query(bounds, sqr);
        collect(body, sqr, results);
      }
    }

    for (body in a) if (body != null) body.collision_mask = 0;
    for (body in b) if (body != null) body.collision_mask = 0;
  }
  /**
   * Finds every Body in `bodies` whose bounds overlap the `body`, using the World's QuadTrees.
   * @param body The Body to check. Each resulting `Collision` has this Body as its `a` Body.
   * @param bodies The group of Bodies to check against.
   * @param world The World whose QuadTrees are queried.
   * @param results Array that the resulting Collisions are pushed to.
   */
  public static function overlap_body_and_bodies_bounds(body:Body, bodies:Array<Body>, world:World, results:Array<Collision>) {
    if (body.disposed || body.shapes.length == 0 || !body.active) return;

    for (member in bodies) if (member != null) member.collision_mask |= IN_B;

    var bounds = stored_bounds(body);
    qr.resize(0);
    world.quadtree.query(bounds, qr);
    collect(body, qr, results);
    if (body.is_dynamic()) {
      sqr.resize(0);
      world.static_quadtree.query(bounds, sqr);
      collect(body, sqr, results);
    }

    for (member in bodies) if (member != null) member.collision_mask = 0;
  }
  /**
   * The bounds to query the QuadTrees with for a Body. Bodies in a World are queried with the same (padded) bounds they were inserted with, so that a
   * Body is found by a query whenever it was inserted - a Body's exact bounds could fall entirely outside the World while its padded bounds don't.
   * Bodies that aren't in a World fall back to their exact bounds.
   */
  static inline function stored_bounds(body:Body):AABB {
    return body.stored_bounds(query_bounds);
  }
  /**
   * Turns a QuadTree query into Collisions between `body` and each result that is marked as part of the Listener's `b` group.
   */
  static inline function collect(body:Body, data:Array<QuadTreeData>, results:Array<Collision>) {
    for (r in data) {
      var member = r.body;
      if (member == null
        || member == body
        || (member.collision_mask & IN_B) == 0
        || member.disposed
        || member.shapes.length == 0
        || !member.active
        // Neither Body can move (both are static, asleep, or one of each), so neither could have moved into the other
        || (!body.can_move() && !member.can_move())
        || !layer_match(body, member)) continue;
      // If both Bodies are in both groups, this pair will also be found from the other Body's side - only accept it from the Body with the lower id, so each pair is reported once
      if ((member.collision_mask & IN_A) != 0 && (body.collision_mask & IN_B) != 0 && body.id > member.id) continue;
      results.push(Collision.get(body, member));
    }
  }

  public static function overlap_body_and_body_bounds(a:Body, b:Body):Null<Collision> {
    if (a.disposed || b.disposed || a.shapes.length == 0 || b.shapes.length == 0 || !a.active || !b.active || a == b || !layer_match(a, b) || !a.can_move()
      && !b.can_move()) return null;
    var ab = a.bounds();
    var bb = b.bounds();
    var col = ab.overlaps(bb);
    ab.put();
    bb.put();
    return col ? Collision.get(a, b) : null;
  }

  static inline function layer_match(a:Body, b:Body) {
    return a.layer_mask.is_empty() || b.layer_mask.is_empty() || (a.layer_mask.contains(b.layers) && b.layer_mask.contains(a.layers));
  }
}
