<p align="center">
  <img src="https://raw.githubusercontent.com/austineast/echo/gh-pages/logo.png">
</p>

# echo
A 2D Physics library written in Haxe.

![Build Status](https://github.com/AustinEast/echo/actions/workflows/build-and-release.yml/badge.svg)

Echo focuses on maintaining a simple API that is easy to integrate into any engine/framework (Heaps, OpenFL, Kha, etc). All Echo needs is an update loop and its ready to go!

Try the [Samples 🎮](https://austineast.dev/echo)!

Check out the [API 📖](https://austineast.dev/echo/api/echo/Echo)!

# Features
* Semi-implicit euler integration physics
* SAT-powered collision detection
* Concave colliders through convex decomposition
* Quadtree for broadphase collision querying
* Collision listeners to provide collision callbacks
* Full physics (contact-based resolution with rotation and friction) or Arcade physics (position/velocity separation only), configurable per World or per Listener
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
* Polygon (Convex)

SAT only works with convex Shapes, so a concave collider is built out of several convex ones. Set `decompose` on a Polygon's options and Echo splits the vertices into convex pieces for you, adding one Shape to the Body per piece (see [Convex Decomposition](#convex-decomposition)):

```haxe
// An "L" shaped Body
var b = new Body({
  x: 100,
  y: 100,
  shape: {
    type: POLYGON,
    decompose: true,
    vertices: [
      new Vector2(0, 0),
      new Vector2(40, 0),
      new Vector2(40, 10),
      new Vector2(10, 10),
      new Vector2(10, 40),
      new Vector2(0, 40)
    ]
  }
});
```

When a Shape is added to a Body, it's transform (x, y, rotation) becomes relative to its parent Body. In this case, a Shape's local transform can still be accessed through `shape.local_x`, `shape.local_y`, and `shape.local_rotation`.

It's important to note that all Shapes (including Rectangles) have their origins centered.

### Lines and Rays

Use Lines to perform Linecasts against other Lines, Bodies, and Shapes. Check out the `Echo` class for various methods to preform Linecasts.

A `Ray` is like a Line with a start point and a direction, but no end - it extends endlessly (or up to an optional `max_distance`). Rays are cast with `Echo.raycast()` / `Echo.raycast_all()`, and return the same `Intersection` results as Linecasts:

```haxe
// An endless Ray pointing right from (0, 0)
var ray = Ray.get(0, 0, 1, 0);
var hit = ray.raycast(world.members, world);
if (hit != null) trace('hit ${hit.body} at ${hit.closest.hit}, ${hit.closest.distance} units away');
```

### Listeners

Listeners keep track of collisions between Bodies - enacting callbacks and physics responses depending on their configurations. Once you add a `Listener` to a `World`, it will automatically update itself as the `World` is stepped forward.

### Arcade vs Full Physics

Echo can resolve collisions in one of two modes:

* **Full** (the default) - Collisions are resolved at their contact points, like in Box2D. Off-center impacts spin Bodies, circles roll down slopes, and friction (from each Body's `Material`) slows Bodies sliding along surfaces.
* **Arcade** - Collisions only push Bodies apart and adjust their velocities along the collision normal. Bodies are never rotated by a collision and there is no friction, which is ideal for platformers, top-down games, and anything where you want predictable, "video-gamey" movement.

The mode is set on the `World` with the `arcade` flag, and can be overridden by individual Listeners:

```haxe
// Every collision in this World uses arcade physics
var world = Echo.start({width: 640, height: 360, gravity_y: 100, arcade: true});

// ...except collisions between the crates and the ground, which use full physics
world.listen(crates, ground, {arcade: false});
```

In full physics, each Body has an `inertia` (its resistance to being spun) that is automatically calculated from its shapes, mass, and `Material.density` - just like `mass`. Setting a Body's `inertia` to `0` stops it from being rotated by collisions entirely, which is handy for things like a player character. A `Material`'s `friction` and `static_friction` values only take effect in full physics.

Full physics uses the contact points generated during collision detection, which are available on `CollisionData.contacts` (and can be visualized with `Debug.draw_contacts`).

## Utilities

Echo ships with a handful of utilities in `echo.util` that build on the core simulation.

### TileMap Colliders

`echo.util.TileMap` turns an `Array<Int>` of tile data into static collider Bodies, so a tile-based level can be dropped straight into a `World`:

```haxe
// `data` is a flat Array of tile indices, row by row. Tiles with an index >= start_index (1 by default) are solid.
var tiles = echo.util.TileMap.generate(data, tile_width, tile_height, width_in_tiles, height_in_tiles, offset_x, offset_y);
for (b in tiles) world.add(b);

world.listen(player, tiles);
```

`generate()` merges runs of neighboring tiles into as few Rects as possible, which keeps the Body count (and the broadphase) small. Pass a `shapes` Array of `TileShape`s to give particular tile indices a slope (`slope_direction` plus a `Gentle`/`Sharp` and `Thick`/`Thin` `slope_shape`) or any custom `ShapeOptions`, and an `ignore` Array for indices that shouldn't collide at all. `generate_grid()` skips the merging and produces one Body per tile, which is handy when tiles need to be removed individually at runtime.

### Convex Decomposition

`echo.util.Decompose` splits a concave set of vertices into convex ones, which is what backs the `decompose` Shape option. Call it directly when the pieces are needed outside of a `Body` (to render them, cache them, or build the Shapes by hand):

```haxe
// An Array of convex vertex Arrays
var pieces = Decompose.convex(vertices);

// The same thing, as an Array of Polygons ready to be added to a Body
var polygons = Polygon.get_from_concave_vertices(0, 0, 0, vertices);
for (p in polygons) body.add_shape(p);
```

The decomposition uses [Mark Bayazit's algorithm](https://mpen.ca/406/bayazit), which keeps the piece count low without adding many extra vertices. It expects a **simple** polygon - one whose edges don't cross each other, with no holes - so vertices coming from an editor or a file are worth validating with `Decompose.is_simple()` first. `Decompose` also provides `is_convex()`, `signed_area()`, `centroid()`, `remove_collinear()` and `remove_duplicates()` for working with raw vertices.

Since a decomposed collider is just a `Body` with several Shapes, the pieces are laid out once when the Body is created - deforming a collider at runtime means decomposing the new vertices again. Note that Bodies still collide against each piece separately, so a Shape sliding across the seam between two pieces can catch on the internal edge.

### Bezier Curves

`echo.util.Bezier` is a path made of `Linear`, `Quadratic`, or `Cubic` Bezier curves defined by control points. The curve is flattened into a cached `points` Array and a `lines` Array of `Line`s, so it can be drawn, walked along, or used with Linecasts:

```haxe
var bezier = new Bezier([new Vector2(0, 0), new Vector2(50, -80), new Vector2(100, -80), new Vector2(150, 0)], Cubic);

var midpoint = bezier.get_point(0.5); // a point on the curve, from 0.0 (start) to 1.0 (end)
var quarter = bezier.get_point_at_length(bezier.length * 0.25);
for (line in bezier.lines) line.linecast(world.members, world);
```

Control points can be added, moved (`set_control_point()` optionally drags a cubic curve's neighboring handles along), and removed at any time; the cached lines are rebuilt lazily. `line_mode` chooses how the curve is flattened: `Segments(amount)` for a fixed number of Lines per curve, or `Subdivisions(options)` (the default) for adaptive subdivision that puts more Lines where the curve bends. Static helpers such as `Bezier.point_on_cubic_curve()` are available for one-off calculations.

### History (Undo/Redo)

Passing a `history` size to a World's options makes it record every Body's transform and velocities each step in a ring buffer of that many states. `world.undo()` and `world.redo()` then step the simulation backwards and forwards through the recorded states - useful for debugging (the sample app binds them to the arrow keys) or for rewind mechanics:

```haxe
var world = Echo.start({width: 640, height: 360, history: 600}); // keep the last 10 seconds at 60 steps/second
world.undo();
world.redo();
```

`echo.util.History` (and the `Ring` buffer it is built on) can also be used on their own for any undo/redo stack.

### Debug Drawing

`echo.util.Debug` draws a World's Bodies, Shapes, bounds, QuadTrees, Collision contact points, Linecast/Raycast results, Bezier curves, and Verlet composites. It only depends on a few drawing primitives, so any renderer can be supported by extending it and overriding `draw_line()`, `draw_rect()`, `draw_circle()`, and `clear()`. Ready-made `HeapsDebug` and `OpenFLDebug` subclasses are included (compiled in when the `heaps` or `openfl` defines are present):

```haxe
var debug = new echo.util.HeapsDebug(s2d);
debug.draw_quadtree = false;
debug.draw_contacts = true;

// In your render loop
debug.draw(world);
```

### Verlet (Softbody) Simulation

`echo.util.verlet.Verlet` is a standalone Verlet integration simulation for softbody effects (ropes, cloth, jelly boxes). It is built from `Dot`s (points), `Constraint`s (distance, pin, rotation), and `Composite`s (groups of Dots and Constraints, roughly analogous to a `Body`).

Dots can collide with Shapes and with the Bodies of a regular `World` - a Dot that ends up inside (or passes through) a solid Shape is pushed back out through the face it entered. This is a one-way interaction: Bodies affect Dots, but Dots do not push Bodies around.

```haxe
var verlet = new Verlet({
  width: 640,
  height: 360,
  gravity_y: 20,
  world: world // Dots collide with this World's Bodies
});

// Dots can also collide with standalone Shapes
verlet.colliders.push(Shape.circle(320, 180, 32));

var rope = Verlet.rope([for (i in 0...10) new Vector2(80 + i * 10, 70)], 0.7, [0]);
verlet.add(rope);

// In your update loop
verlet.step(dt);
```

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

Support is currently available for the following libraries (activated by adding the listed compiler flag to your project's build parameters):

| Library | Compiler Flag |
| --- | --- |
| [hxmath](https://github.com/tbrosman/hxmath) | ECHO_USE_HXMATH |
| [vector-math](https://github.com/haxiomic/vector-math) | ECHO_USE_VECTORMATH |
| [zerolib](https://github.com/01010111/zerolib) | ECHO_USE_ZEROLIB |
| [heaps](https://heaps.io) | ECHO_USE_HEAPS |

(pull requests for other libraries happily accepted!)

If you compile your project with a standard `.hxml`:
```hxml
# hxmath support
-lib hxmath
-D ECHO_USE_HXMATH
```

For OpenFL users, add one of the following into your `Project.xml`:
```xml
<!-- hxmath support -->
<haxelib name="hxmath" />
<haxedef name="ECHO_USE_HXMATH" />
```

For Kha users, add one of the following into your `khafile.js`:
```js
// hxmath support
project.addLibrary('hxmath');
project.addDefine('ECHO_USE_HXMATH');
```

# Examples

## Basic
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
      iterations: 2, // Sets the number of Physics iterations that will occur each time the World steps.
      arcade: false // Use full, Box2D-style physics (the default). Set to true for arcade physics (no rotation or friction from collisions).
    });

    // Create a Body with a Circle Collider and add it to the World
    var a = world.make({
      material: {elasticity: 0.2},
      shape: {
        type: CIRCLE,
        radius: 16,
      }
    });

    // Create a Body with a Rectangle collider and add it to the World
    // This Body will be static (ie have a Mass of `0`), rendering it as unmovable
    // This is useful for things like platforms or walls.
    var b = world.make({
      mass: STATIC, // Setting this to Static/`0` makes the body unmovable by forces and collisions
      y: 48, // Set the object's Y position below the Circle, so that gravity makes them collide
      material: {elasticity: 0.2},
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

## Samples
Check out the source code for the [Echo Samples](https://austineast.dev/echo/) here: https://github.com/AustinEast/echo/tree/master/sample/state

## Engine/Framework Specific

* [HaxeFlixel](https://haxeflixel.com): https://github.com/AustinEast/echo-flixel
* [Heaps](https://heaps.io): https://github.com/AustinEast/echo-heaps
* [Peyote View](https://github.com/maitag/peote-view): https://github.com/maitag/peote-views-samples/tree/master/echo
* [HaxePunk](https://haxepunk.com): https://github.com/XANOZOID/EchoHaxePunk


# Development

Echo has a test suite and a benchmark under `test/suite`. Both build to JavaScript and run with node (edit the `.hxml` output lines to target HashLink instead):

```
haxe test-suite.hxml
haxe bench.hxml
```

The suite cross-checks the broadphase against a brute force scan, and covers full physics resolution, verlet collisions, and raycasting. The benchmark reports milliseconds per step for the sample's stacking scenes in both arcade and full physics.

# Roadmap
## Later
* Sleeping Body optimations
* Constraints
* Persistent contacts with warm-starting (improves stacking stability in full physics)
* Compiler Flag to turn off a majority of inlined functions (worse performance, but MUCH smaller filesize)
