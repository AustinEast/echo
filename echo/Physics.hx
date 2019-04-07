package echo;

import echo.data.Data;

using hxmath.math.MathUtil;
using hxmath.math.Vector2;
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
    world.for_each_dynamic((member) -> {
      if (member.active) {
        member.last_x = member.x;
        member.last_y = member.y;
        member.last_rotation = member.rotation;
        // Compute Velocity
        member.velocity.x = compute_velocity(member.velocity.x, member.acceleration.x, member.drag.x, member.max_velocity.x, dt);
        member.velocity.y = compute_velocity(member.velocity.y, member.acceleration.y, member.drag.y, member.max_velocity.y, dt);
        // Apply Velocity
        member.x += member.velocity.x * member.inverse_mass * dt;
        member.y += member.velocity.y * member.inverse_mass * dt;
        // Apply Rotations
        member.rotation += member.rotational_velocity * dt;
      }
    });
  }
  /**
   * Separates a World's Bodies that have collided. Use `Collisions.query()` to query for collisions
   * @param world
   * @param dt
   */
  public static function separate(world:World, dt:Float) {
    for (listener in world.listeners.members) {
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
    if (!cd.sa.solid || !cd.sb.solid || !a.active || !b.active || a.mass == 0 && b.mass == 0) return;
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
  }

  public static inline function compute_velocity(v:Float, a:Float, d:Float, m:Float, dt:Float) {
    // Apply Acceleration to Velocity
    if (a != 0) {
      v += a * dt;
    }
    else if (d != 0) {
      d = d * dt;
      if (v - d > 0) v -= d;
      else if (v + d < 0) v += d;
      else v = 0;
    }
    // Clamp Velocity if it has a Max
    if (m != 0) v = v.clamp(-m, m);
    return v;
  }
}
