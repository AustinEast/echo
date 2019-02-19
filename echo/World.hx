package echo;

import hxmath.math.Vector2;
import echo.util.QuadTree;
import echo.Listener;
import echo.Echo;
import haxe.ds.Vector;

class World extends Group {
  public var width:Float;
  public var height:Float;
  public var x:Float;
  public var y:Float;
  public var gravity(default, null):Vector2;
  public var quadtree:QuadTree;
  public var listeners:Listeners;
  public var iterations:Int;
  public var history:Vector<WorldState>;

  public function new(options:WorldOptions) {
    super(options.members);
    width = options.width < 1 ? throw("World must have a width of at least 1") : options.width;
    height = options.height < 1 ? throw("World must have a width of at least 1") : options.height;
    x = options.x == null ? 0 : options.x;
    y = options.y == null ? 0 : options.y;
    gravity = new Vector2(options.gravity_x == null ? 0 : options.gravity_x, options.gravity_y == null ? 0 : options.gravity_y);
    quadtree = QuadTree.get();
    listeners = new Listeners(this, options.listeners);
    iterations = options.iterations == null ? 5 : options.iterations;
  }

  override function clear() {
    super.clear();
    listeners.clear();
  }

  override function dispose() {
    super.dispose();
    gravity = null;
    quadtree.put();
    listeners.dispose();
    listeners = null;
    history = null;
  }
}

typedef WorldOptions = {
  var width:Float;
  var height:Float;
  var ?x:Float;
  var ?y:Float;
  var ?gravity_x:Float;
  var ?gravity_y:Float;
  var ?members:Array<Body>;
  var ?listeners:Array<Listener>;
  var ?iterations:Int;
  var ?history:Int;
}
