package echo;

import echo.Body;
import echo.util.SAT;
import echo.util.QuadTree;

class Collisions {
  /**
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

    // Process the Colliders
    for (collider in world.colliders.members) {
      // BroadPhase
      var results:Array<Collision> = [];
      switch (collider.a.type) {
        case BODY:
          switch (collider.b.type) {
            case BODY:
              var col = body_and_body(cast collider.a, cast collider.b);
              if (col != null) results.push(col);
            case GROUP:
              results = body_and_group(cast collider.a, cast collider.b, world.quadtree);
          }
        case GROUP:
          switch (collider.b.type) {
            case BODY:
              results = body_and_group(cast collider.a, cast collider.b, world.quadtree);
            case GROUP:
              results = group_and_group(cast collider.a, cast collider.b, world.quadtree);
          }
      }
      // NarrowPhase
      collider.last_collisions = collider.collisions.copy();
      collider.collisions = [];
      for (result in results) {
        // Filter out self collisions
        if (result.a.id == result.b.id) continue;
        // Filter out duplicate pairs
        if (collider.collisions.filter((pair) -> {
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
        collider.collisions.push(result);
        sa.put();
        sb.put();
      }
    }
  }

  public static function notify(world) {}

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
