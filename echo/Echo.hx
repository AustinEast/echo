package echo;

import echo.State.StateOptions;
import haxe.ds.Vector;

class Echo {
  // var states:History;
  // var observers:
  public static function start(options:StateOptions):State {
    return new State(options);
  }

  public static function step(state:State, dt:Float) {
    // Broadphase

    // Narrowphase

    // Integrate

    // Iterate NarrowPhase && Integrate

    // Notify New State and Collisions to Listeners
  }

  public static function undo(state:State):State {
    return state;
  }

  public static function redo(state:State):State {
    return state;
  }

  // returns observable
  public static function listen() {}
}
