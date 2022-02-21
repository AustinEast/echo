package echo;

import haxe.ds.Either;
import echo.util.Disposable;
import echo.Body;
import echo.data.Data;
import echo.data.Options;
import echo.util.BodyOrBodies;
/**
 * Data Structure used to listen for Collisions between Bodies.
 */
@:structInit()
class Listener {
  public static var defaults(get, null):ListenerOptions;
  /**
   * The first Body or Array of Bodies the listener checks each step.
   */
  public var a:Either<Body, Array<Body>>;
  /**
   * The second Body or Array of Bodies the listener checks each step.
   */
  public var b:Either<Body, Array<Body>>;
  /**
   * Flag that determines if Collisions found by this listener should separate the Bodies. Defaults to `true`.
   */
  public var separate:Bool;
  /**
   * Store of the latest Collisions.
   */
  public var collisions:Array<Collision>;
  /**
   * Store of the Collisions from the Prior Frame.
   */
  public var last_collisions:Array<Collision>;
  /**
   * A callback function that is called on the first frame that a collision starts.
   */
  @:optional public var enter:Body->Body->Array<CollisionData>->Void;
  /**
   * A callback function that is called on frames when two Bodies are continuing to collide.
   */
  @:optional public var stay:Body->Body->Array<CollisionData>->Void;
  /**
   * A callback function that is called when a collision between two Bodies ends.
   */
  @:optional public var exit:Body->Body->Void;
  /**
   * A callback function that allows extra logic to be run on a potential collision.
   *
   * If it returns true, the collision is valid. Otherwise the collision is discarded and no physics resolution/collision callbacks occur
   */
  @:optional public var condition:Body->Body->Array<CollisionData>->Bool;
  /**
   * Store of the latest quadtree query results
   */
  @:optional public var quadtree_results:Array<Collision>;
  /**
   * Percentage of correction along the collision normal to be applied to seperating bodies. Helps prevent objects sinking into each other.
   */
  public var percent_correction:Float;
  /**
   * Threshold determining how close two separating bodies must be before position correction occurs. Helps reduce jitter.
   */
  public var correction_threshold:Float;

  static function get_defaults():ListenerOptions return {
    separate: true,
    percent_correction: 0.9,
    correction_threshold: 0.013
  }
}
/**
 * Container used to store Listeners
 */
class Listeners implements Disposable {
  public var members:Array<Listener>;

  public function new(?members:Array<Listener>) {
    this.members = members == null ? [] : members;
  }
  /**
   * Add a new Listener to the collection.
   * @param a The first `Body` or Array of Bodies to collide against.
   * @param b The second `Body` or Array of Bodies to collide against.
   * @param options Options to define the Listener's behavior.
   * @return The new Listener.
   */
  public function add(a:BodyOrBodies, b:BodyOrBodies, ?options:ListenerOptions):Listener {
    options = echo.util.JSON.copy_fields(options, Listener.defaults);
    var listener:Listener = {
      a: a,
      b: b,
      separate: options.separate,
      collisions: [],
      last_collisions: [],
      quadtree_results: [],
      correction_threshold: options.correction_threshold,
      percent_correction: options.percent_correction
    };
    if (options.enter != null) listener.enter = options.enter;
    if (options.stay != null) listener.stay = options.stay;
    if (options.exit != null) listener.exit = options.exit;
    if (options.condition != null) listener.condition = options.condition;
    members.push(listener);
    return listener;
  }
  /**
   * Removes a Listener from the Container.
   * @param listener Listener to remove.
   * @return The removed Listener.
   */
  public function remove(listener:Listener):Listener {
    members.remove(listener);
    return listener;
  }
  /**
   * Clears the collection of all Listeners.
   */
  public function clear() {
    members.resize(0);
  }
  /**
   * Disposes of the collection. Do not use once disposed.
   */
  public function dispose() {
    members = null;
  }

  public inline function iterator():Iterator<Listener> return members.iterator();
}
