package echo.data;

@:enum
abstract ShapeType(Int) from Int to Int {
  var RECT;
  var CIRCLE;
  var POLYGON;
}
