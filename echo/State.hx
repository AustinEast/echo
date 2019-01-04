package echo;

import haxe.ds.Vector;
import echo.util.QuadTree;

class State {
  public var width:Float;
  public var height:Float;
  public var bodies:Array<Body>;
  public var quadtrees:Array<QuadTree>;

  var iterations:Int;
  var history:Vector<Array<Body>>;

  public function new(options:StateOptions) {
    width = options.width < 1 ? throw("State must have a width of at least 1") : options.width;
    height = options.height < 1 ? throw("State must have a width of at least 1") : options.height;
    bodies = options.bodies == null ? [] : options.bodies;
    
    quadtrees = [];
  }

  public function add(body:Body):Body {
    bodies.remove(body);
    bodies.push(body);
    return body;
  }

  public function remove(body:Body):Body {
    return body;
  }
}

typedef StateOptions = {
  var width:Float;
  var height:Float;
  var ?bodies:Array<Body>;
  var ?iterations:Int;
  var ?history:Int;
}
