package echo;

import haxe.ds.Vector;

class Echo {
  // var states:History;
  // var observers:
  public static function start(?options:StateOptions):State {
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

typedef StateOptions = {
  var width:Float;
  var height:Float;
  var ?bodies:Array<Body>;
  var ?iterations:Int;
  var ?history:Int;
}

class State {
  var width:Float;
  var height:Float;
  var bodies:Array<Body>;
  var iterations:Int;
  var history:Vector<Array<Body>>;

  public function new(?options:StateOptions) {}

  public function add(body:Body):Body {
    bodies.remove(body);
    bodies.push(body);
    return body;
  }

  public function remove(body:Body):Body {
    return body;
  }
}
