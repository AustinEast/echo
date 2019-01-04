package;

import echo.Body;
import echo.Echo;
import echo.State;
import echo.util.Debug;
import glib.Random;

class Main extends hxd.App {
  var state:State;
  var debug:HeapsDebug;
  var body_count:Int = 50;
  /**
   * Initialize the Scene
   */
  override function init() {
    // Set the Background color of the Scene
    engine.backgroundColor = 0xff222034;
    // Create a State to hold all the Physics Bodies
    state = Echo.start({width: engine.width, height: engine.height});
    // Add a bunch of Physics Bodies to the State
    for (i in 0...body_count) {
      state.add(new Body({
        x: Random.range(0, state.width),
        y: Random.range(0, state.height)
      }));
    }
    // Create a Debug drawer to display debug graphics
    debug = new HeapsDebug(s2d);
  }
  /**
   * Update the Scene
   * @param dt Delta Time
   */
  override function update(dt:Float) {
    // Step the State Forward
    Echo.step(state, dt);
    // Draw the new State
    debug.draw(state);
  }
  /**
   * Scale the debug canvas when the window is resized
   */
  override public function onResize() {
    var scaleFactorX:Float = engine.width / state.width;
    var scaleFactorY:Float = engine.height / state.height;
    var scaleFactor:Float = Math.min(scaleFactorX, scaleFactorY);
    if (scaleFactor < 1) scaleFactor = 1;
    debug.canvas.setScale(scaleFactor);
  }

  static function main() {
    new Main();
  }
}
