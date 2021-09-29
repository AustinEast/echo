package echo.util.controller;

import echo.math.Vector2;
import echo.shape.Rect;

class LinecastController {
  public var x(get, set):Float;
  public var y(get, set):Float;
  public var collider:Rect;

  var skin_width:Float = 0.25;
  var distance_between_casts:Float = 0.25;

  var horizontal_cast_count:Int;
  var vertical_cast_count:Int;
  var horizontal_cast_spacing:Float;
  var vertical_cast_spacing:Float;

  var top_left_origin:Vector2;
  var top_right_origin:Vector2;
  var bottom_left_origin:Vector2;
  var bottom_right_origin:Vector2;

  public function new(x:Float, y:Float, width:Float, height:Float) {
    collider = Rect.get(x, y, width, height);
    top_left_origin = new Vector2(0, 0);
    top_right_origin = new Vector2(0, 0);
    bottom_left_origin = new Vector2(0, 0);
    bottom_right_origin = new Vector2(0, 0);
    calculate_cast_spacing();
  }

  function update_cast_origins() {
    var bounds = collider.clone();
    bounds.width -= skin_width * 2;
    bounds.height -= skin_width * 2;

    top_left_origin.set(bounds.left, bounds.bottom);
    top_right_origin.set(bounds.right, bounds.bottom);
    bottom_left_origin.set(bounds.left, bounds.top);
    bottom_right_origin.set(bounds.right, bounds.top);

    bounds.put();
  }

  function calculate_cast_spacing() {
    var bounds = collider.clone();
    bounds.width -= skin_width * 2;
    bounds.height -= skin_width * 2;

    horizontal_cast_count = Math.floor(bounds.height / distance_between_casts);
    vertical_cast_count = Math.floor(bounds.width / distance_between_casts);

    horizontal_cast_spacing = bounds.height / (horizontal_cast_count - 1);
    vertical_cast_spacing = bounds.width / (vertical_cast_count - 1);

    bounds.put();
  }

  inline function get_x() return collider.x;

  inline function get_y() return collider.y;

  inline function set_x(v) return collider.x = v;

  inline function set_y(v) return collider.y = v;
}
