package echo;

import echo.Collider;
import echo.Collisions;
import echo.util.QuadTree;
import haxe.ds.Vector;

class State extends Group {
  public var width:Float;
  public var height:Float;
  public var colliders:Colliders;
  public var collisions:Array<Collision>;
  public var quadtrees:Array<QuadTree>;
  public var iterations:Int;
  public var history:Vector<Array<Body>>;

  public function new(options:StateOptions) {
    super(options.members);
    width = options.width < 1 ? throw("State must have a width of at least 1") : options.width;
    height = options.height < 1 ? throw("State must have a width of at least 1") : options.height;
    colliders = new Colliders();
    quadtrees = [];
  } 
}

typedef StateOptions = {
  var width:Float;
  var height:Float;
  var ?members:Array<Body>;
  var ?iterations:Int;
  var ?history:Int;
}
