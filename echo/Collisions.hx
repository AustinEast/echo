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
        // Filter out self collisions
        if (result.a.id == result.b.id) continue;
        // Filter out duplicate pairs
        if (listener.collisions.filter((pair) -> {
            if (pair.a.id == result.a.id && pair.b.id == result.b.id) return true;
            if (pair.b.id == result.a.id && pair.a.id == result.b.id) return true;
            return false;
          }).length > 0) continue;
        // Preform the full collision check
        var sa;
        var sb;
        if (result.a.mass == 0) {
          sa = result.a.cache.shape.clone();
          sa.position.x += result.a.cache.x;
          sa.position.y += result.a.cache.y;
        }
        else {
          sa = result.a.shape.clone();
          sa.position.addWith(result.a.position);
        }
        if (result.b.mass == 0) {
          sb = result.b.cache.shape.clone();
          sb.position.x += result.b.cache.x;
          sb.position.y += result.b.cache.y;
        }
        else {
          sb = result.b.shape.clone();
          sb.position.addWith(result.b.position);
        }
        result.data = sa.collides(sb);
        // If there was no collision, continue
        if (result.data == null) continue;
        // Check if the collision passes the listener's condition if it has one
        if (listener.condition != null && listener.condition(result.a, result.b, result.data)) continue;
        result.a.collided = result.b.collided = true;
        listener.collisions.push(result);
        sa.put();
        sb.put();
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
          if (listener.enter != null && listener.last_collisions.find((f) -> return f.a == c.a && f.b == c.b || f.a == c.b && f.b == c.a) == null) {
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
    if (body.shape == null || !body.active || body.mass == 0) return [];
    var bounds = body.bounds();
    var results:Array<Collision> = [];
    for (result in world.quadtree.query(bounds)) {
      group.members.map((member) -> if (result.id == member.id) results.push({a: body, b: member}));
    }
    for (result in world.static_quadtree.query(bounds)) {
      group.members.map((member) -> if (result.id == member.id) results.push({a: body, b: member}));
    }
    bounds.put();
    return results;
  }

  static function body_and_body(a:Body, b:Body):Null<Collision> {
    if (a.shape == null || b.shape == null || !a.active || !b.active || a == b || a.mass == 0 && b.mass == 0) return null;
    var ab = a.bounds();
    var bb = b.bounds();
    var col = ab.collides(bb);
    ab.put();
    bb.put();
    return col == null ? null : {a: a, b: b};
  }
}
