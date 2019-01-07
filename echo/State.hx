package echo;

import haxe.ds.Vector;
import echo.util.QuadTree;

class State extends Group {
  public var width:Float;
  public var height:Float;

  var iterations:Int;
  var history:Vector<Array<Body>>;

  public function new(options:StateOptions) {
    super(options.bodies);
    width = options.width < 1 ? throw("State must have a width of at least 1") : options.width;
    height = options.height < 1 ? throw("State must have a width of at least 1") : options.height;    
  }
}

typedef StateOptions = {
  var width:Float;
  var height:Float;
  var ?bodies:Array<Body>;
  var ?iterations:Int;
  var ?history:Int;
}
