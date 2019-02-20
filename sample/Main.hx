package;

import echo.World;
import echo.util.Debug;
import glib.FSM;
import state.*;

using echo.Echo;

class Main extends BaseApp {
  public static var scene:h2d.Scene;
  public static var state_text:h2d.Text;

  var width:Int = 640;
  var height:Int = 360;
  var world:World;
  var members_text:h2d.Text;
  var fps_text:h2d.Text;

  override function init() {
    // Create a World to hold all the Physics Bodies
    world = Echo.start({
      width: width,
      height: height,
      gravity_y: 20,
      iterations: 5
    });
    // Create a State Manager and pass it the World and the first Sample
    fsm = new FSM<World>(world, Type.createInstance(sample_states[index], null));
    // Create a Debug drawer to display debug graphics
    debug = new HeapsDebug(s2d);
    // Set the Background color of the Scene
    engine.backgroundColor = 0x45283c;
    // Set the Heaps Scene size
    s2d.setFixedSize(width, height);
    // Get a static reference to the Heaps scene so we can access it later
    scene = s2d;
    // Add the UI elements
    add_ui();
  }

  override function update(dt:Float) {
    // Update the current Sample State
    fsm.update(dt);
    // Step the World Forward
    world.step(dt);
    // Draw the new World
    debug.draw(world);
    // Update GUI text
    members_text.text = 'Bodies: ${world.members.length}';
    fps_text.text = 'FPS: ${engine.fps}';
  }

  function add_ui() {
    fui = new h2d.Flow(s2d);
    fui.y = 5;
    fui.padding = 5;
    fui.verticalSpacing = 5;
    fui.isVertical = true;
    var bui = new h2d.Flow(s2d);
    bui.padding = 5;
    bui.verticalSpacing = 5;
    bui.isVertical = true;
    bui.y = s2d.height - 90;
    state_text = addText("Sample: ", bui);
    members_text = addText("Bodies: ", bui);
    fps_text = addText("FPS: ", bui);
    var buttons = new h2d.Flow(bui);
    buttons.horizontalSpacing = 2;

    addButton("Previous", previous_state, buttons);
    addButton("Restart", reset_state, buttons);
    addButton("Next", next_state, buttons);
    addSlider("Gravity", () -> return world.gravity.y, (v) -> world.gravity.y = v, -100, 100);
    addSlider("Iterations", () -> return world.iterations, (v) -> world.iterations = Std.int(v), 1, 10);
  }

  static function main() {
    new Main();
  }
}
