package echo.data;

@:enum
abstract ShapeType(Int) from Int to Int {
  var RECT = 0;
  var CIRCLE = 1;
  var POLYGON = 2;
}
