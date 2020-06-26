package state;

import echo.Body;
import echo.World;
import ghost.FSM;

class BaseState extends State<World> {
  override public function exit(world:World) world.clear();

  inline function offscreen(b:Body, world:World) {
    var bounds = b.bounds();
    var check = bounds.min_y > world.height || bounds.max_x < 0 || bounds.min_x > world.width;
    bounds.put();
    return check;
  }
}
