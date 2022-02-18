package echo.data;

@:enum abstract ShapeType(Int) from Int to Int {
  var RECT;
  var CIRCLE;
  var POLYGON;
}

@:enum abstract ForceType(Int) from Int to Int {
  var ACCELERATION;
  var VELOCITY;
  var POSITION;
}
