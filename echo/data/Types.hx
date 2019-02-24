package echo.data;

import echo.data.Data;

@:enum
abstract EchoType(Int) from Int to Int {
  var BODY = 0;
  var GROUP = 1;
}

@:enum
abstract ShapeType(Int) from Int to Int {
  var RECT = 0;
  var CIRCLE = 1;
  var POLYGON = 2;
}
