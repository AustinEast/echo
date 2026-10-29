import echo.Echo;
import echo.data.Types.ShapeType;

class WorldBoundsTest {
  static function main() {
    check_single_shape(10, 20, 4, 6, 8, 17, 4, 6);
    check_single_shape(-10, -20, 4, 6, -12, -23, 4, 6);

    var world = Echo.start({width: 100, height: 100});
    world.make({x: -10, y: -20, shape: {type: ShapeType.RECT, width: 4, height: 6}});
    world.make({x: 12, y: 13, shape: {type: ShapeType.RECT, width: 2, height: 2}});
    world.set_from_members();
    assert_bounds(world, -12, -23, 25, 37);
    world.dispose();
  }

  static function check_single_shape(x:Float, y:Float, width:Float, height:Float, left:Float, top:Float, expected_width:Float,
      expected_height:Float) {
    var world = Echo.start({width: 100, height: 100});
    world.make({x: x, y: y, shape: {type: ShapeType.RECT, width: width, height: height}});
    world.set_from_members();
    assert_bounds(world, left, top, expected_width, expected_height);
    world.dispose();
  }

  static function assert_bounds(world:echo.World, x:Float, y:Float, width:Float, height:Float) {
    if (world.x != x || world.y != y || world.width != width || world.height != height) {
      throw 'expected world bounds ($x,$y,$width,$height), got (${world.x},${world.y},${world.width},${world.height})';
    }
  }
}
