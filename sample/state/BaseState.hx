package state;

import echo.Body;
import echo.World;
import ghost.FSM;

class BaseState extends State<World> {
  override public function exit(world:World) world.clear();

  inline function offscreen(b:Body, world:World) {
    var bounds = b.bounds();
    var check = bounds.top > world.height || bounds.right < 0 || bounds.left > world.width;
    bounds.put();
    return check;
  }
}
