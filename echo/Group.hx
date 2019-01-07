package echo;

import echo.util.QuadTree;

class Group {
  public var bodies:Array<Body>;
  public var quadtrees:Array<QuadTree>;

  public function new(?bodies:Array<Body>) {
    this.bodies = bodies == null ? [] : bodies;
    this.quadtrees = [];
  }

  public function add(body:Body):Body {
    if (body != null) {
      bodies.remove(body);
      bodies.push(body);
    }
    return body;
  }

  public function remove(body:Body):Body {
    bodies.remove(body);
    return body;
  }
}
