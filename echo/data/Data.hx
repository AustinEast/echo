package echo.data;

import echo.shape.Rect;
import hxmath.math.Vector2;

typedef Collision = {
  /**
   * Body A.
   */
  var a:Body;
  /**
   * Body B.
   */
  var b:Body;
  /**
   * Array containing Data from Each Collision found between the two Bodies' Shapes.
   */
  var data:Array<CollisionData>;
}

typedef CollisionData = {
  /**
   * Shape A.
   */
  var ?sa:Shape;
  /**
   * Shape B.
   */
  var ?sb:Shape;
  /**
   * The length of Shape A's penetration into Shape B.
   */
  var overlap:Float;
  /**
   * The normal vector (direction) of Shape A's penetration into Shape B.
   */
  var normal:Vector2;
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
