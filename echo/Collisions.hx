package echo;

import echo.Body;
import echo.util.SAT;
import echo.util.QuadTree;
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
    for (member in world.members) {
      member.collided = false;
      if (member.active) {
        var b = member.bounds();
        if (b != null) world.quadtree.insert({id: member.id, bounds: b, flag: false});
      }
    }

    // Process the Listeners
    for (listener in world.listeners.members) {
      // BroadPhase
      var results:Array<Collision> = [];
      switch (listener.a.type) {
        case BODY:
          switch (listener.b.type) {
            case BODY:
              var col = body_and_body(cast listener.a, cast listener.b);
              if (col != null) results.push(col);
            case GROUP:
              results = body_and_group(cast listener.a, cast listener.b, world.quadtree);
          }
        case GROUP:
          switch (listener.b.type) {
            case BODY:
              results = body_and_group(cast listener.a, cast listener.b, world.quadtree);
            case GROUP:
              results = group_and_group(cast listener.a, cast listener.b, world.quadtree);
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
        var sa = result.a.shape.clone();
        var sb = result.b.shape.clone();
        sa.position.addWith(result.a.position);
        sb.position.addWith(result.b.position);
        result.data = sa.collides(sb);
        if (result.data == null) continue;
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
      if (listener.callback == null) continue;
      if (listener.condition == null) for (c in listener.collisions) listener.callback(c.a, c.b, cast c.data);
      else for (c in listener.collisions) if (listener.condition(cast c.a, cast c.b, cast c.data)) listener.callback(c.a, c.b, cast c.data);
    }
  }

  static function group_and_group(a:Group, b:Group, ?quadtree:QuadTree):Array<Collision> {
    if (a.members.length == 0 || b.members.length == 0) return [];
    var results:Array<Collision> = [];
    for (member in a.members) if (member.active) results = results.concat(body_and_group(member, b, quadtree));
    return results;
  }

  static function body_and_group(body:Body, group:Group, ?quadtree:QuadTree):Array<Collision> {
    if (body.shape == null || !body.active) return [];
    var bounds = body.bounds();
    var results:Array<Collision> = [];
    for (result in quadtree.query(bounds)) {
      group.members.map((member) -> if (result.id == member.id) results.push({a: body, b: member}));
    }
    bounds.put();
    return results;
  }

  static function body_and_body(a:Body, b:Body):Null<Collision> {
    if (a.shape == null || b.shape == null || !a.active || !b.active || a == b) return null;
    var ab = a.bounds();
    var bb = b.bounds();
    var col = ab.collides(bb);
    ab.put();
    bb.put();
    return col == null ? null : {a: a, b: b};
  }
}

typedef Collision = {
  var a:Body;
  var b:Body;
  var ?data:CollisionData;
}
