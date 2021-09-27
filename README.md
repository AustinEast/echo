<p align="center">
  <img src="https://raw.githubusercontent.com/austineast/echo/gh-pages/logo.png">
</p>

# echo
A 2D Physics library written in Haxe.

[![Build Status](https://travis-ci.org/AustinEast/echo.svg?branch=master)](https://travis-ci.org/AustinEast/echo)

Echo focuses on maintaining a simple API that is easy to integrate into any engine/framework (Heaps, OpenFL, Kha, etc). All Echo needs is an update loop and its ready to go!

Try the [Samples 🎮](https://austineast.dev/echo)!

Check out the [API 📖](https://austineast.dev/echo/api/)!

# Features
* Semi-implicit euler integration physics
* SAT-powered collision detection
* Quadtree for broadphase collision querying
* Collision listeners to provide collision callbacks
* Physics State History Management with Built-in Undo/Redo functionality
* Extendable debug drawing

# Getting Started

Echo requires [Haxe 4.2+](https://haxe.org/download/) to run.

Install the library from haxelib:
```
haxelib install echo
```
Alternatively the dev version of the library can be installed from github:
```
haxelib git echo https://github.com/AustinEast/echo.git
```

Then for standard Haxe applications, include the library in your project's `.hxml`:
```hxml
-lib echo
```

For OpenFL users, add the library into your `Project.xml`:

```xml
<haxelib name="echo" />
```

For Kha users (who don't use haxelib), clone echo to thee `Libraries` folder in your project root, and then add the following to your `khafile.js`:

```js
project.addLibrary('echo');
```

# Usage

## Concepts

### Echo

The `Echo` Class holds helpful utility methods to help streamline the creation and management of Physics Simulations.

### World

A `World` is an Object representing the state of a Physics simulation and it configurations. 

### Bodies

A `Body` is an Object representing a Physical Body in a `World`. A `Body` has a position, velocity, mass, optional collider shapes, and many other properties that are used in a `World` simulation.

### Shapes

A Body's collider is represented by different Shapes. Without a `Shape` to define it's form, a `Body` can be thought of a just a point in the `World` that cant collide with anything.

Available Shapes:
* Rectangle
* Circle
* Polygon (Convex Only)

When a Shape is added to a Body, it's transform (x, y, rotation) becomes relative to its parent Body. In this case, a Shape's local transform can still be accessed through `shape.local_x`, `shape.local_y`, and `shape.local_rotation`.

It's important to note that all Shapes (including Rectangles) have their origins centered.

### Lines

Use Lines to perform Linecasts against other Lines, Bodies, and Shapes. Check out the `Echo` class for various methods to preform Linecasts.

### Listeners

Listeners keep track of collisions between Bodies - enacting callbacks and physics responses depending on their configurations. Once you add a `Listener` to a `World`, it will automatically update itself as the `World` is stepped forward.

## Integration

### Codebase Integration
Echo has a couple of ways to help integrate itself into codebases through the `Body` class. 

First, the `Body` class has two public fields named `on_move` and `on_rotate`. If these are set on a body, they'll be called any time the body moves or rotates. This is useful for things such as syncing the Body's transform with external objects:
```haxe
var body = new echo.Body();
body.on_move = (x,y) -> entity.position.set(x,y);
body.on_rotate = (rotation) -> entity.rotation = rotation;
```

Second, a build macro is available to add custom fields to the `Body` class, such as a reference to an `Entity` class:

in build.hxml:
```hxml
--macro echo.Macros.add_data("entity", "some.package.Entity")
```

in Main.hx
```haxe
var body = new echo.Body();
body.entity = new some.package.Entity();
```

### Other Math Library Integration

Echo comes with basic implementations of common math structures (Vector2, Vector3, Matrix3), but also allows these structures to be extended and used seamlessly with other popular Haxe math libraries. 

Support is currently available for [hxmath](https://github.com/tbrosman/hxmath), [vector-math](https://github.com/haxiomic/vector-math), and [zerolib](https://github.com/01010111/zerolib).

(pull requests for other libraries happily accepted!)

If you compile your project with a standard `.hxml`, add one of these to your file:
```hxml
# hxmath support
-lib hxmath
-D ECHO_USE_HXMATH

# vector-math support
-lib vector-math
-D ECHO_USE_VECTORMATH

# zerolib support
-lib zerolib
-D ECHO_USE_ZEROLIB
```

For OpenFL users, add one of the following into your `Project.xml`:
```xml
<!-- hxmath support -->
<haxelib name="hxmath" />
<haxedef name="ECHO_USE_HXMATH" />

<!-- vector-math support -->
<haxelib name="vector-math" />
<haxedef name="ECHO_USE_VECTORMATH" />

<!-- zerolib support -->
<haxelib name="zerolib" />
<haxedef name="ECHO_USE_ZEROLIB" />
```

For Kha users, add one of the following into your `khafile.js`:
```js
// hxmath support
project.addLibrary('hxmath');
project.addDefine('ECHO_USE_HXMATH');

// vector-math support
project.addLibrary('vector-math');
project.addDefine('ECHO_USE_VECTORMATH');

// zerolib support
project.addLibrary('zerolib');
project.addDefine('ECHO_USE_ZEROLIB');
```

# Examples

## Engine/Framework Examples

* [HaxeFlixel](https://haxeflixel.com): https://github.com/AustinEast/echo-flixel
* [Heaps](https://heaps.io): https://github.com/AustinEast/echo-heaps
* [Peyote View](https://github.com/maitag/peote-view): https://github.com/maitag/peote-views-samples/tree/master/echo
* [HaxePunk](https://haxepunk.com): https://github.com/XANOZOID/EchoHaxePunk

## Basic Example
```haxe
import echo.Echo;

class Main {
  static function main() {
    // Create a World to hold all the Physics Bodies
    // Worlds, Bodies, and Listeners are all created with optional configuration objects.
    // This makes it easy to construct object configurations, reuse them, and even easily load them from JSON!
    var world = Echo.start({
      width: 64, // Affects the bounds for collision checks.
      height: 64, // Affects the bounds for collision checks.
      gravity_y: 20, // Force of Gravity on the Y axis. Also available for the X axis.
      iterations: 2 // Sets the number of Physics iterations that will occur each time the World steps.
    });

    // Create a Body with a Circle Collider and add it to the World
    var a = world.make({
      elasticity: 0.2,
      shape: {
        type: CIRCLE,
        radius: 16,
      }
    });

    // Create a Body with a Rectangle collider and add it to the World
    // This Body will have a Mass of zero, rendering it as unmovable
    // This is useful for things like platforms or walls.
    var b = world.make({
      mass: 0, // Setting this to zero makes the body unmovable by forces and collisions
      y: 48, // Set the object's Y position below the Circle, so that gravity makes them collide
      elasticity: 0.2,
      shape: {
        type: RECT,
        width: 10,
        height: 10
      }
    });

    // Create a listener and attach it to the World.
    // This listener will react to collisions between Body "a" and Body "b", based on the configuration options passed in
    world.listen(a, b, {
      separate: true, // Setting this to true will cause the Bodies to separate on Collision. This defaults to true
      enter: (a, b, c) -> trace("Collision Entered"), // This callback is called on the first frame that a collision starts
      stay: (a, b, c) -> trace("Collision Stayed"), // This callback is called on frames when the two Bodies are continuing to collide
      exit: (a, b) -> trace("Collision Exited"), // This callback is called when a collision between the two Bodies ends
    });

    // Set up a Timer to act as an update loop (at 60fps)
    new haxe.Timer(16).run = () -> {
      // Step the World's Physics Simulation forward (at 60fps)
      world.step(16 / 1000);
      // Log the World State in the Console
      echo.util.Debug.log(world);
    }
  }
}
```

# Roadmap
## Sooner
* Endless length Line support
* Update Readme with info on the various utilities (Tilemap, Bezier, etc)
## Later
* Allow Concave Polygons (through Convex Decomposition)
* Sleeping Body optimations
* Constraints
* Compiler Flag to turn off a majority of inlined functions (worse performance, but MUCH smaller filesize)
