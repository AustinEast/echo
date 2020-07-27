package echo;

import hxmath.math.Vector2;
import echo.data.Data;
import echo.Listener;

using hxmath.math.MathUtil;
using echo.util.Ext;
/**
 * Class containing methods for performing Physics simulations on a World
 */
class Physics {
  static final zero = Vector2.zero;
  /**
   * Applies movement forces to a World's Bodies
   * @param world World to step forward
   * @param dt elapsed time since the last step
   */
  public static function step(world:World, dt:Float) {
    world.for_each_dynamic((member) -> {
      if (!member.disposed && member.active) {
        member.lock_sync();
        member.last_x = member.x;
        member.last_y = member.y;
        member.last_rotation = member.rotation;
        // Compute Velocity
        var accel_x = member.acceleration.x;
        var accel_y = member.acceleration.y;
        if (!member.kinematic) {
          accel_x += world.gravity.x * member.gravity_scale;
          accel_y += world.gravity.y * member.gravity_scale;
        }
        member.velocity.x = compute_velocity(member.velocity.x, accel_x, member.drag.x, member.max_velocity.x, dt);
        member.velocity.y = compute_velocity(member.velocity.y, accel_y, member.drag.y, member.max_velocity.y, dt);
        // Apply the Body's mass_velocity_length and drag_length
        if (member.drag_length > 0 && member.acceleration == zero && member.velocity != zero) {
          member.velocity.normalizeTo(member.velocity.length - member.drag_length * dt);
        }
        if (member.max_velocity_length > 0 && member.velocity.length > member.max_velocity_length) {
          member.velocity.normalizeTo(member.max_velocity_length);
        }
        // Apply Velocity
        member.x += member.velocity.x * member.inverse_mass * dt;
        member.y += member.velocity.y * member.inverse_mass * dt;
        // Apply Rotations
        if (member.max_rotational_velocity > 0) member.rotational_velocity = member.rotational_velocity.clamp(-member.max_rotational_velocity,
          member.max_rotational_velocity);
        // Apply Drag to Rotations
        if (member.rotational_drag > 0) {
          if (member.rotational_velocity > 0) {
            member.rotational_velocity -= member.rotational_drag * dt;
            if (member.rotational_velocity < 0) member.rotational_velocity = 0; // drag should never make us rotate in the opposite direction
          }
          else {
            member.rotational_velocity += member.rotational_drag * dt;
            if (member.rotational_velocity > 0) member.rotational_velocity = 0; // drag should never make us rotate in the opposite direction
          }
        }
        member.rotation += member.rotational_velocity * dt;
        member.unlock_sync();
      }
    });
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
  public static function resolve(a:Body, b:Body, cd:CollisionData, correction_threshold:Float = 0.013, percent_correction:Float = 0.9) {
    // Do not resolve if either objects arent solid
    if (!cd.sa.solid || !cd.sb.solid || !a.active || !b.active || a.disposed || b.disposed || a.is_static() && b.is_static()) return;

    a.lock_sync();
    b.lock_sync();

    // Calculate relative velocity
    var rvx = a.velocity.x - b.velocity.x;
    var rvy = a.velocity.y - b.velocity.y;
    // Calculate relative velocity in terms of the normal direction
    var vel_to_normal = rvx * cd.normal.x + rvy * cd.normal.y;
    var inv_mass_sum = a.inverse_mass + b.inverse_mass;
    // Do not resolve if velocities are separating
    if (vel_to_normal > 0) {
      // Calculate elasticity
      var e = (a.elasticity + b.elasticity) * 0.5;
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

    a.unlock_sync();
    b.unlock_sync();
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
