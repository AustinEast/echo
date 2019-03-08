package echo.data;

import echo.shape.Rect;
import hxmath.math.Vector2;

typedef Collision = {
  var a:Body;
  var b:Body;
  var ?data:CollisionData;
}

typedef CollisionData = {
  /**
   * The length of shape 1's penetration into shape 2.
   */
  var overlap:Float;
  /**
   * The normal vector (direction) of shape 1's penetration into shape 2.
   */
  var normal:Vector2;
  /**
   * TODO: Provide a direction const, similar to Flixel's
   */
  var ?direction:Int;
}

typedef IntersectionData = {}

typedef QuadTreeData = {
  /**
   * Id of the Data.
   */
  var id:Int;
  /**
   * Bounds of the Data.
   */
  var ?bounds:Rect;
  /**
   * Helper flag to check if this Data has been counted during queries.
   */
  var flag:Bool;
}

@:enum
abstract Direction(Int) from Int to Int {
  var TOP = 0;
}
