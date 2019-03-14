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
    for (member in world.members) {
      if (member.mass == 0) continue;
      // Compute Velocity
      member.velocity.x = compute_velocity(member.velocity.x, member.acceleration.x, member.drag.x, member.max_velocity.x, dt);
      member.velocity.y = compute_velocity(member.velocity.y, member.acceleration.y, member.drag.y, member.max_velocity.y, dt);
      // Apply Velocity
      member.position.addWith(member.velocity * member.inverse_mass * dt);
      // Apply Rotations
      member.rotation += member.rotational_velocity * dt;
    }
  }
  /**
   * Separates a World's Bodies that have collided. Use `Collisions.query()` to query for collisions
   * @param world
   * @param dt
   */
  public static function separate(world:World, dt:Float) {
    for (listener in world.listeners.members) {
      if (listener.separate) for (collision in listener.collisions) resolve(collision.a, collision.b, collision.data);
    }
  }
  /**
   * Resolves a Collision between two Bodies, separating them if the conditions are correct.
   * @param a the first `Body` in the Collision
   * @param b the second `Body` in the Collision
   * @param cd Data related to the Collision
   */
  public static function resolve(a:Body, b:Body, cd:CollisionData) {
    // Do not resolve if either objects arent solid
    if (!a.solid || !b.solid || a.mass == 0 && b.mass == 0) return;
    // Calculate relative velocity
    var rv = a.velocity - b.velocity;
    // Calculate relative velocity in terms of the normal direction
    var vel_to_normal = rv * cd.normal;
    var inv_mass_sum = a.inverse_mass + b.inverse_mass;
    // Do not resolve if velocities are separating
    if (vel_to_normal > 0) {
      // Calculate elasticity
      var e = (a.elasticity + b.elasticity) * 0.5;
      // Calculate impulse scalar
      var j = (-(1 + e) * vel_to_normal) / inv_mass_sum;
      var impulse = -j * cd.normal;
      // Apply impulse
      var mass_sum = a.mass + b.mass;
      var ratio = a.mass / mass_sum;
      a.velocity.subtractWith(impulse * a.inverse_mass);
      ratio = b.mass / mass_sum;
      b.velocity.addWith(impulse * b.inverse_mass);
    }
    // Provide some positional correction to the objects to help prevent jitter
    var correction = (Math.max(cd.overlap - 0.013, 0) / inv_mass_sum) * 0.8 * cd.normal;
    a.position.subtractWith(a.inverse_mass * correction);
    b.position.addWith(b.inverse_mass * correction);
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
