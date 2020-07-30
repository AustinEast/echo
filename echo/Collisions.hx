package echo;

import echo.util.QuadTree;
import echo.Body;
import echo.data.Data;
import echo.Listener;

using Lambda;
/**
 * Class containing methods for performing Collisions on a World
 */
class Collisions {
  /**
   * Updates the World's dynamic QuadTree with any Bodies that have moved.
   */
  public static function update_quadtree(world:World) {
    world.for_each(b -> {
      if (!b.disposed) {
        b.collided = false;
        for (shape in b.shapes) {
          shape.collided = false;
          if (shape.type == RECT) {
            var r:echo.shape.Rect = cast shape;
            if (r.transformed_rect != null) r.transformed_rect.collided = false;
          }
        }
        if (b.active && b.is_dynamic() && b.dirty) {
          if (b.quadtree_data.bounds == null) b.quadtree_data.bounds = b.bounds();
          else b.bounds(b.quadtree_data.bounds);
          world.quadtree.update(b.quadtree_data);
        }
        b.dirty = false;
      }
    });
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
              var col = body_and_body(ba, bb);
              if (col != null) listener.quadtree_results.push(col);
            case Right(ab):
              body_and_bodies(ba, ab, world, listener.quadtree_results, world.quadtree);
          }
        case Right(aa):
          switch (listener.b) {
            case Left(bb):
              body_and_bodies(bb, aa, world, listener.quadtree_results, world.quadtree);
            case Right(ab):
              bodies_and_bodies(aa, ab, world, listener.quadtree_results, world.quadtree);
          }
      }
      // Narrow Phase
      for (collision in listener.last_collisions) collision.put();
      listener.last_collisions = listener.collisions.copy();
      listener.collisions.resize(0);
      for (result in listener.quadtree_results) {
        // Filter out disposed bodies
        if (result.a.disposed || result.b.disposed) {
          result.put();
          continue;
        }
        // Filter out self collisions
        if (result.a.id == result.b.id) {
          result.put();
          continue;
        }
        // Filter out duplicate pairs
        var flag = false;
        for (collision in listener.collisions) {
          if ((collision.a.id == result.a.id && collision.b.id == result.b.id)
            || (collision.b.id == result.a.id && collision.a.id == result.b.id)) {
            flag = true;
            break;
          }
        }
        if (flag) {
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
            if (listener.enter != null
              && listener.last_collisions.find((f) -> return f.a == c.a && f.b == c.b || f.a == c.b && f.b == c.a) == null) {
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
          if (!lc.a.disposed
            && !lc.b.disposed
            && listener.collisions.find((f) -> return f.a == lc.a && f.b == lc.b || f.a == lc.b && f.b == lc.a) == null) {
            listener.exit(lc.a, lc.b);
          }
        }
      }
    }
  }

  static function bodies_and_bodies(a:Array<Body>, b:Array<Body>, world:World, results:Array<Collision>, quadtree:QuadTree) {
    if (a.length == 0 || b.length == 0) return;
    for (body in a) if (!body.disposed && body.active && body.is_dynamic()) body_and_bodies(body, b, world, results, quadtree);
  }

  static var qr:Array<QuadTreeData> = [];
  static var sqr:Array<QuadTreeData> = [];

  static function body_and_bodies(body:Body, bodies:Array<Body>, world:World, results:Array<Collision>, quadtree:QuadTree) {
    if (!body.disposed && body.shapes.length == 0 || !body.active || body.is_static()) return;
    var bounds = body.bounds();
    qr.resize(0);
    sqr.resize(0);
    quadtree.query(bounds, qr);
    world.static_quadtree.query(bounds, sqr);
    for (member in bodies) {
      if (member.disposed) continue;
      for (result in (member.is_dynamic() ? qr : sqr)) {
        if (result.id == member.id) results.push(Collision.get(body, member));
      }
    }
    bounds.put();
  }

  static function body_and_body(a:Body, b:Body):Null<Collision> {
    if (a.disposed || b.disposed || a.shapes.length == 0 || b.shapes.length == 0 || !a.active || !b.active || a == b || a.is_static() && b.is_static()) return
      null;
    var ab = a.bounds();
    var bb = b.bounds();
    var col = ab.overlaps(bb);
    ab.put();
    bb.put();
    return col ? Collision.get(a, b) : null;
  }
}
