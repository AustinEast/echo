package echo;

import echo.Body;
import echo.util.QuadTree;
import echo.data.Data;

using Lambda;
/**
 * Class containing methods for performing Collisions on a World
 */
class Collisions {
  /**
   * Queries a World's Listeners for Collisions
   * TODO: Keep a Quadtree of Cached Static Objects
   */
  public static function query(world:World) {
    // Populate the Quadtree
    if (world.quadtree != null) world.quadtree.put();
    world.quadtree = QuadTree.get(world.x + (world.width * 0.5), world.y + (world.height * 0.5), world.width, world.height);
    world.for_each((b) -> {
      b.collided = false;
      for (shape in b.shapes) shape.collided = false;
      if (b.active && b.mass > 0) {
        b.bounds(b.cache.quadtree_data.bounds);
        world.quadtree.insert(b.cache.quadtree_data);
      }
    });

    // Process the Listeners
    for (listener in world.listeners.members) {
      // BroadPhase
      var results:Array<Collision> = [];
      switch (listener.a.echo_type) {
        case BODY:
          switch (listener.b.echo_type) {
            case BODY:
              var col = body_and_body(cast listener.a, cast listener.b);
              if (col != null) results.push(col);
            case GROUP:
              results = body_and_group(cast listener.a, cast listener.b, world);
          }
        case GROUP:
          switch (listener.b.echo_type) {
            case BODY:
              results = body_and_group(cast listener.a, cast listener.b, world);
            case GROUP:
              results = group_and_group(cast listener.a, cast listener.b, world);
          }
      }
      // NarrowPhase
      listener.last_collisions = listener.collisions.copy();
      listener.collisions = [];
      for (result in results) {
        // Filterout self collisions/
        if (result.a.id == result.b.id) continue;
        // Filter out duplicate pairs
        if (listener.collisions.filter((pair) -> {
          if (pair.a.id == result.a.id && pair.b.id == result.b.id) return true;
          if (pair.b.id == result.a.id && pair.a.id == result.b.id) return true;
          return false;
        }).length > 0) continue;
        // Preform the full collision check
        var use_a_cache = result.a.mass == 0;
        var ssa = use_a_cache ? result.a.cache.shapes : result.a.shapes;

        for (sa in ssa) {
          var sac = sa.clone();
          if (use_a_cache) {
            sac.x += result.a.cache.x;
            sac.y += result.a.cache.y;
          }
          else {
            sac.x += result.a.x;
            sac.y += result.a.y;
          }
          var use_b_cache = result.b.mass == 0;
          var ssb = use_b_cache ? result.b.cache.shapes : result.b.shapes;
          for (sb in ssb) {
            var sbc = sb.clone();
            if (use_b_cache) {
              sbc.x += result.b.cache.x;
              sbc.y += result.b.cache.y;
            }
            else {
              sbc.x += result.b.x;
              sbc.y += result.b.y;
            }
            var col = sac.collides(sbc);
            if (col != null) {
              col.sa = sa;
              col.sb = sb;
              result.data.push(col);
            }
            sbc.put();
          }
          sac.put();
        }
        // If there was no collision, continue
        if (result.data.length == 0) continue;
        // Check if the collision passes the listener's condition if it has one
        if (listener.condition != null && listener.condition(result.a, result.b, result.data)) continue;
        for (data in result.data) data.sa.collided = data.sb.collided = true;
        result.a.collided = result.b.collided = true;
        listener.collisions.push(result);
      }
    }
  }
  /**
   * Enacts the Callbacks defined in a World's Listeners
   */
  public static function notify(world:World) {
    for (listener in world.listeners.members) {
      if (listener.enter != null || listener.stay != null) {
        for (c in listener.collisions) {
          if (listener.enter != null
            && listener.last_collisions.find((f) -> return f.a == c.a && f.b == c.b || f.a == c.b && f.b == c.a) == null) {
            listener.enter(c.a, c.b, c.data);
          }
          else if (listener.stay != null) {
            listener.stay(c.a, c.b, c.data);
          }
        }
      }
      if (listener.exit != null) {
        for (lc in listener.last_collisions) {
          if (listener.collisions.find((f) -> return f.a == lc.a && f.b == lc.b || f.a == lc.b && f.b == lc.a) == null) {
            listener.exit(lc.a, lc.b);
          }
        }
      }
    }
  }

  static function group_and_group(a:Group, b:Group, ?world:World):Array<Collision> {
    if (a.members.length == 0 || b.members.length == 0) return [];
    var results:Array<Collision> = [];
    for (member in a.members) if (member.active && member.mass > 0) results = results.concat(body_and_group(member, b, world));
    return results;
  }

  static function body_and_group(body:Body, group:Group, ?world:World):Array<Collision> {
    if (body.shapes.length == 0 || !body.active || body.mass == 0) return [];
    var bounds = body.bounds();
    var results:Array<Collision> = [];
    for (result in world.quadtree.query(bounds)) {
      group.members.map((member) -> if (result.id == member.id) results.push({a: body, b: member, data: []}));
    }
    for (result in world.static_quadtree.query(bounds)) {
      group.members.map((member) -> if (result.id == member.id) results.push({a: body, b: member, data: []}));
    }
    bounds.put();
    return results;
  }

  static function body_and_body(a:Body, b:Body):Null<Collision> {
    if (a.shapes.length == 0 || b.shapes.length == 0 || !a.active || !b.active || a == b || a.mass == 0 && b.mass == 0) return null;
    var ab = a.bounds();
    var bb = b.bounds();
    var col = ab.collides(bb);
    ab.put();
    bb.put();
    return col == null ? null : {a: a, b: b, data: []};
  }
}
