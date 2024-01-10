package echo;

import echo.math.Vector2;
import echo.Listener;
import echo.data.Data;

using echo.util.ext.FloatExt;
/**
 * Class containing methods for performing Physics simulations on a World
 */
class Physics {
  /**
   * Applies movement forces to a World's Bodies
   * @param world World to step forward
   * @param dt elapsed time since the last step
   */
  public static function step(world:World, dt:Float) {
    world.for_each_dynamic(member -> step_body(member, dt, world.gravity.x, world.gravity.y));
  }

  public static inline function step_body(body:Body, dt:Float, gravity_x:Float, gravity_y:Float) {
    if (!body.disposed && body.active) {
      body.last_x = body.x;
      body.last_y = body.y;
      body.last_rotation = body.rotation;
      var accel_x = body.acceleration.x * body.inverse_mass;
      var accel_y = body.acceleration.y * body.inverse_mass;

      // Apply Gravity (after applying body's inverse mass to acceleration)
      if (!body.kinematic) {
        accel_x += gravity_x * body.material.gravity_scale;
        accel_y += gravity_y * body.material.gravity_scale;
      }

      // Apply Acceleration, Drag, and Max Velocity
      body.velocity.x = compute_velocity(body.velocity.x, accel_x, body.drag.x, body.max_velocity.x, dt);
      body.velocity.y = compute_velocity(body.velocity.y, accel_y, body.drag.y, body.max_velocity.y, dt);

      // Apply Linear Drag
      if (body.drag_length > 0 && body.acceleration == Vector2.zero && body.velocity != Vector2.zero) {
        body.velocity.length = body.velocity.length - body.drag_length * dt;
      }

      // Apply Linear Max Velocity
      if (body.max_velocity_length > 0 && body.velocity.length > body.max_velocity_length) {
        body.velocity.length = body.max_velocity_length;
      }

      // Apply Velocity
      body.x += body.velocity.x * dt;
      body.y += body.velocity.y * dt;

      // Apply Rotational Acceleration, Drag, and Max Velocity
      var accel_rot = body.torque * body.inverse_mass;
      body.rotational_velocity = compute_velocity(body.rotational_velocity, accel_rot, body.rotational_drag, body.max_rotational_velocity, dt);

      // Apply Rotational Velocity
      body.rotation += body.rotational_velocity * dt;
    }
  }
  /**
   * Loops through all of a World's Listeners, separating all collided Bodies in the World. Use `Collisions.query()` before calling this to query the World's Listeners for collisions.
   * @param world
   * @param dt
   */
  public static function separate(world:World, ?listeners:Listeners) {
    var members = listeners == null ? world.listeners.members : listeners.members;
    for (listener in members) {
      if (listener.separate) for (collision in listener.collisions) {
        for (i in 0...collision.data.length) resolve(collision.a, collision.b, collision.data[i], listener.correction_threshold, listener.percent_correction);
      }
    }
  }
  /**
   * Resolves a Collision between two Bodies, separating them if the conditions are correct.
   * @param a the first `Body` in the Collision
   * @param b the second `Body` in the Collision
   * @param cd Data related to the Collision
   */
  public static inline function resolve(a:Body, b:Body, cd:CollisionData, correction_threshold:Float = 0.013, percent_correction:Float = 0.9,
      advanced:Bool = false) {
    // Do not resolve if either objects arent solid
    if (!cd.sa.solid || !cd.sb.solid || !a.active || !b.active || a.disposed || b.disposed || a.is_static() && b.is_static()) return;

    // Calculate relative velocity
    var rvx = a.velocity.x - b.velocity.x;
    var rvy = a.velocity.y - b.velocity.y;

    // Calculate relative velocity in terms of the normal direction
    var vel_to_normal = rvx * cd.normal.x + rvy * cd.normal.y;
    var inv_mass_sum = a.inverse_mass + b.inverse_mass;

    // Do not resolve if velocities are separating
    if (vel_to_normal > 0) {
      // Calculate elasticity
      var e = (a.material.elasticity + b.material.elasticity) * 0.5;

      // Calculate impulse scalar
      var j = (-(1 + e) * vel_to_normal) / inv_mass_sum;
      var impulse_x = -j * cd.normal.x;
      var impulse_y = -j * cd.normal.y;

      // Apply impulse
      var mass_sum = a.mass + b.mass;
      var ratio = a.mass / mass_sum;
      if (!a.kinematic) {
        a.velocity.x -= impulse_x * a.inverse_mass;
        a.velocity.y -= impulse_y * a.inverse_mass;
      }
      ratio = b.mass / mass_sum;
      if (!b.kinematic) {
        b.velocity.x += impulse_x * b.inverse_mass;
        b.velocity.y += impulse_y * b.inverse_mass;
      }

      if (advanced) {
        // Calculate static and dynamic friction
        var sf = Math.sqrt(a.material.static_friction * a.material.static_friction + b.material.static_friction * b.material.static_friction);
        var df = Math.sqrt(a.material.friction * a.material.friction + b.material.friction * b.material.friction);

        // TODO - FRICTION / TORQUE / CONTACT POINT RESOLUTION
      }
    }

    // Provide some positional correction to the objects to help prevent jitter
    var correction = (Math.max(cd.overlap - correction_threshold, 0) / inv_mass_sum) * percent_correction;
    var cx = correction * cd.normal.x;
    var cy = correction * cd.normal.y;
    if (!a.kinematic) {
      a.x -= a.inverse_mass * cx;
      a.y -= a.inverse_mass * cy;
    }
    if (!b.kinematic) {
      b.x += b.inverse_mass * cx;
      b.y += b.inverse_mass * cy;
    }
  }

  // TODO
  // public static function resolve_intersection(id:Intersection, correction_threshold:Float = 0.013, percent_correction:Float = 0.9) {}

  public static inline function compute_velocity(v:Float, a:Float, d:Float, m:Float, dt:Float) {
    // Apply Acceleration to Velocity
    if (!a.equals(0)) {
      v += a * dt;
    }
    else if (!d.equals(0)) {
      d = d * dt;
      if (v - d > 0) v -= d;
      else if (v + d < 0) v += d;
      else v = 0;
    }
    // Clamp Velocity if it has a Max
    if (!m.equals(0)) v = v.clamp(-m, m);
    return v;
  }
}
