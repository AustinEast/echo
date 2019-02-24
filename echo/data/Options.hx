package echo.data;

import echo.data.Data;
import echo.data.Types;
import hxmath.math.Vector2;

typedef BodyOptions = {
  var ?shape:ShapeOptions;
  var ?solid:Bool;
  var ?mass:Float;
  var ?x:Float;
  var ?y:Float;
  var ?elasticity:Float;
  var ?velocity_x:Float;
  var ?velocity_y:Float;
  var ?rotational_velocity:Float;
  var ?max_velocity_x:Float;
  var ?max_velocity_y:Float;
  var ?max_rotational_velocity:Float;
  var ?drag_x:Float;
  var ?drag_y:Float;
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

typedef ListenerOptions = {
  var ?separate:Bool;
  var ?callback:Dynamic->Dynamic->Collision->Void;
  var ?condition:Dynamic->Dynamic->Collision->Bool;
}

typedef ShapeOptions = {
  var ?type:ShapeType;
  var ?radius:Float;
  var ?width:Float;
  var ?height:Float;
  var ?points:Array<Vector2>;
  var ?rotation:Float;
  var ?offset_x:Float;
  var ?offset_y:Float;
}

typedef RectOptions = {
  var x:Float;
  var y:Float;
  var width:Float;
  var height:Float;
}

typedef CircleOptions = {
  var x:Float;
  var y:Float;
  var radius:Float;
}

typedef PolygonOptions = {
  var x:Float;
  var y:Float;
  var vertices:Array<Vector2>;
  var rotation:Float;
}

typedef LineOptions = {
  var x:Float;
  var y:Float;
  var dx:Float;
  var dy:Float;
}
