// `using` echo.Echo is prefered over importing it, as it adds in some useful extension methods
using echo.Echo;

class Main {
  static function main() {
    // Create a World to hold all the Physics Bodies
    // Worlds, Bodies, and Listeners are all created with optional configuration objects.
    // This makes it easy to construct obje t configurations, reuse them, and even easily load them from JSON!
    var world = Echo.start({
      width: 64, // Affects the bounds that collision checks.
      height: 64, // Affects the bounds for collision checks.
      gravity_y: 5, // Force of Gravity on the Y axis. Also available on for the X axis.
      iterations: 2 // Sets the number of iterations each time the World steps.
    });

    // Create a Body with a Circle Collider and add it to the World
    world.make({
      shape: {
        type: CIRCLE,
        radius: 16
      }
    });

    // Create a Body with a Rectangle collider and add it to the World
    // This Body will have a Mass of zero, rendering it as unmovable
    // This is useful for things like platforms or walls.
    world.make({
      mass: 0, // Setting this to zero makes the body unmovable by forces and collisions
      y: 48, // Set the object's Y position below the Circle, so that gravity makes them collide
      shape: {
        type: RECT,
        width: 10,
        height: 10
      }
    });

    // Create a basic listener.
    // Calling this with no parameters will cause every object to collide against one another
    world.listen();

    // Set up a Timer to act as an update loop
    new haxe.Timer(16).run = () -> {
      // Step the World's Physics Simulation forward
      world.step(16 / 1000);
      // Log the World State in the Console
      echo.util.Debug.log(world);
    }
  }
}
