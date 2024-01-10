package;

import hxd.Window;
import hxd.Key;
import echo.Echo;
import echo.World;
import echo.util.Debug;
import util.FSM;
import state.*;

class Main extends BaseApp {
  public static var instance:Main;

  public var scene:h2d.Scene;
  public var state_text:h2d.Text;
  public var gravity_slider:h2d.Slider;
  public var iterations_slider:h2d.Slider;
  public var playing:Bool = true;

  var width:Int = 640;
  var height:Int = 360;
  var world:World;
  var members_text:h2d.Text;
  var fps_text:h2d.Text;

  override function init() {
    instance = this;

    // Create a World to hold all the Physics Bodies
    world = Echo.start({
      width: width,
      height: height,
      gravity_y: 100,
      iterations: 5,
      history: 1000
    });

    // Reduce Quadtree depths - our World is very small, so not many subdivisions of the Quadtree are actually needed.
    // This can help with performance by limiting the Quadtree's overhead on simulations with small Body counts!
    world.quadtree.max_depth = 3;
    world.static_quadtree.max_depth = 3;

    // Increase max contents per Quadtree depth - can help reduce Quadtree subdivisions in smaller World sizes.
    // Tuning these Quadtree settings can be very useful when optimizing for performance!
    world.quadtree.max_contents = 20;
    world.static_quadtree.max_contents = 20;

    // Set up our Sample States
    sample_states = [
      PolygonState, StackingState, MultiShapeState, ShapesState, GroupsState, StaticState, LinecastState, Linecast2State, TileMapState, TileMapState2,
      BezierState, VerletState
    ];
    index = 0;
    // Create a State Manager and pass it the World and the first Sample
    fsm = new FSM<World>(world, Type.createInstance(sample_states[index], []));
    // Create a Debug drawer to display debug graphics
    debug = new HeapsDebug(s2d);
    // Set the Background color of the Scene
    engine.backgroundColor = 0x45283c;
    // Set the Heaps Scene size
    s2d.scaleMode = LetterBox(width, height);
    // Get a static reference to the Heaps scene so we can access it later
    scene = s2d;
    // Add the UI elements
    add_ui();
  }

  override function update(dt:Float) {
    // Draw the World
    debug.draw(world);

    if (world.history != null) {
      // Press Left to undo
      if (Key.isDown(Key.LEFT)) {
        world.undo();
        playing = false;
      }
      // Press Right to redo
      if (Key.isDown(Key.RIGHT)) {
        world.redo();
        playing = false;
      }
      // Press Space to play/pause
      if (Key.isPressed(Key.SPACE)) playing = !playing;
    }
    // Hold Shift for slowmo debugging
    var fdt = Key.isDown(Key.SHIFT) ? dt * 0.3 : dt;
    // Update the current Sample State
    fsm.step(fdt);
    // Step the World Forward, with a fixed step rate of 60 per second
    if (playing) world.step(fdt, 60);

    // Update GUI text
    members_text.text = 'Bodies: ${world.count}';
    fps_text.text = 'FPS: ${engine.fps}';
  }

  function add_ui() {
    fui = new h2d.Flow(s2d);
    fui.y = 5;
    fui.padding = 5;
    fui.verticalSpacing = 5;
    fui.layout = Vertical;

    var tui = new h2d.Flow(s2d);
    tui.padding = 5;
    tui.verticalSpacing = 5;
    tui.layout = Vertical;
    tui.y = s2d.height - 90;
    fps_text = addText("FPS: ", tui);
    members_text = addText("Bodies: ", tui);
    state_text = addText("Sample: ", tui);
    var buttons = new h2d.Flow(tui);
    buttons.horizontalSpacing = 2;

    var bui = new h2d.Flow(s2d);
    bui.padding = 5;
    bui.verticalSpacing = 5;
    bui.layout = Vertical;
    bui.y = s2d.height - 65;
    bui.x = s2d.width - 150;
    addText("Arrow Keys: Undo/Redo", bui);
    addText("Spacebar: Pause/Play", bui);
    addText("Hold Shift: Slowmo", bui);

    addButton("Previous", previous_state, buttons);
    addButton("Restart", reset_state, buttons);
    addButton("Next", next_state, buttons);
    gravity_slider = addSlider("Gravity", () -> return world.gravity.y, (v) -> world.gravity.y = v, -100, 300);
    iterations_slider = addSlider("Iterations", () -> return world.iterations, (v) -> world.iterations = Std.int(v), 1, 10, true);
  }

  static function main() {
    new Main();
  }
}
