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
    world.for_each_dynamic(member -> step_body(member, dt, world.gravity.x, world.gravity.y, world.arcade));
  }

  public static inline function step_body(body:Body, dt:Float, gravity_x:Float, gravity_y:Float, arcade:Bool = false) {
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
      // Arcade physics keeps the legacy behavior of scaling torque by mass. Full physics scales it by the Body's inertia.
      var accel_rot = body.torque * (arcade ? body.inverse_mass : body.inverse_inertia);
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
      if (listener.separate) {
        var arcade = listener.arcade == null ? world.arcade : listener.arcade;
        for (collision in listener.collisions) {
          for (i in 0...collision.data.length) resolve(collision.a, collision.b, collision.data[i], listener.correction_threshold, listener.percent_correction,
            arcade);
        }
      }
    }
  }
  /**
   * Resolves a Collision between two Bodies, separating them if the conditions are correct.
   * @param a the first `Body` in the Collision
   * @param b the second `Body` in the Collision
   * @param cd Data related to the Collision
   * @param correction_threshold Threshold determining how close two separating bodies must be before position correction occurs.
   * @param percent_correction Percentage of correction along the collision normal to be applied to seperating bodies.
   * @param arcade If `true`, the Collision only affects the Bodies' velocities (no rotation). If `false`, the Collision is resolved at its contact points, applying rotational impulses and friction.
   */
  public static inline function resolve(a:Body, b:Body, cd:CollisionData, correction_threshold:Float = 0.013, percent_correction:Float = 0.9,
      arcade:Bool = false) {
    // Do not resolve if either objects arent solid
    if (!cd.sa.solid || !cd.sb.solid || !a.active || !b.active || a.disposed || b.disposed || a.is_static() && b.is_static()) return;

    // Full physics requires contact points to compute rotational impulses. Fall back to arcade resolution if none are available.
    if (!arcade && cd.contact_count > 0) resolve_contacts(a, b, cd);
    else resolve_velocity(a, b, cd);

    // Provide some positional correction to the objects to help prevent jitter
    var inv_mass_sum = a.inverse_mass + b.inverse_mass;
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
  /**
   * Arcade impulse resolution - applies a single impulse along the collision normal to the Bodies' velocities. Rotation is unaffected.
   */
  static inline function resolve_velocity(a:Body, b:Body, cd:CollisionData) {
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
      if (!a.kinematic) {
        a.velocity.x -= impulse_x * a.inverse_mass;
        a.velocity.y -= impulse_y * a.inverse_mass;
      }
      if (!b.kinematic) {
        b.velocity.x += impulse_x * b.inverse_mass;
        b.velocity.y += impulse_y * b.inverse_mass;
      }
    }
  }
  /**
   * Full impulse resolution - applies normal and friction impulses at each contact point of the Collision, affecting both the Bodies' velocities and rotational velocities.
   *
   * Based on the sequential impulse method used by Box2D and Randy Gaul's Impulse Engine.
   */
  public static function resolve_contacts(a:Body, b:Body, cd:CollisionData) {
    // Kinematic bodies are treated as having infinite mass - they affect others, but are never moved themselves
    var ima = a.kinematic ? 0. : a.inverse_mass;
    var imb = b.kinematic ? 0. : b.inverse_mass;
    var iia = a.kinematic ? 0. : a.inverse_inertia;
    var iib = b.kinematic ? 0. : b.inverse_inertia;
    if (ima + imb == 0) return;

    var nx = cd.normal.x;
    var ny = cd.normal.y;

    // Calculate elasticity and friction
    var e = (a.material.elasticity + b.material.elasticity) * 0.5;
    var sf = Math.sqrt(a.material.static_friction * a.material.static_friction + b.material.static_friction * b.material.static_friction);
    var df = Math.sqrt(a.material.friction * a.material.friction + b.material.friction * b.material.friction);

    // Bodies store rotational velocity in degrees/second, but the impulse math needs radians/second
    var wa = a.rotational_velocity.deg_to_rad();
    var wb = b.rotational_velocity.deg_to_rad();

    var count = cd.contact_count;
    for (i in 0...count) {
      var contact = cd.contacts[i];
      // Lever arms from each Body's center to the contact point
      var rax = contact.x - a.x;
      var ray = contact.y - a.y;
      var rbx = contact.x - b.x;
      var rby = contact.y - b.y;

      // Relative velocity of B with respect to A at the contact point (linear + angular)
      var rvx = b.velocity.x - wb * rby - a.velocity.x + wa * ray;
      var rvy = b.velocity.y + wb * rbx - a.velocity.y - wa * rax;

      // Relative velocity along the normal
      var contact_vel = rvx * nx + rvy * ny;

      // Do not resolve if velocities are separating
      if (contact_vel > 0) continue;

      var ra_cross_n = rax * ny - ray * nx;
      var rb_cross_n = rbx * ny - rby * nx;
      var inv_mass_sum = ima + imb + ra_cross_n * ra_cross_n * iia + rb_cross_n * rb_cross_n * iib;
      if (inv_mass_sum == 0) continue;

      // Calculate normal impulse scalar, distributed across all contact points
      var j = -(1 + e) * contact_vel / inv_mass_sum / count;
      var ix = nx * j;
      var iy = ny * j;

      // Apply normal impulse
      a.velocity.x -= ix * ima;
      a.velocity.y -= iy * ima;
      wa -= iia * (rax * iy - ray * ix);
      b.velocity.x += ix * imb;
      b.velocity.y += iy * imb;
      wb += iib * (rbx * iy - rby * ix);

      // Recalculate relative velocity after the normal impulse
      rvx = b.velocity.x - wb * rby - a.velocity.x + wa * ray;
      rvy = b.velocity.y + wb * rbx - a.velocity.y - wa * rax;

      // Tangent direction - the relative velocity with the normal component removed
      var dot = rvx * nx + rvy * ny;
      var tx = rvx - nx * dot;
      var ty = rvy - ny * dot;
      var tl = Math.sqrt(tx * tx + ty * ty);
      if (tl.equals(0)) continue;
      tx /= tl;
      ty /= tl;

      // Calculate friction impulse scalar
      var jt = -(rvx * tx + rvy * ty) / inv_mass_sum / count;
      if (jt.equals(0)) continue;

      // Coulomb's law - clamp the friction impulse by the normal impulse
      var fx:Float;
      var fy:Float;
      if (Math.abs(jt) < j * sf) {
        fx = tx * jt;
        fy = ty * jt;
      }
      else {
        fx = tx * -j * df;
        fy = ty * -j * df;
      }

      // Apply friction impulse
      a.velocity.x -= fx * ima;
      a.velocity.y -= fy * ima;
      wa -= iia * (rax * fy - ray * fx);
      b.velocity.x += fx * imb;
      b.velocity.y += fy * imb;
      wb += iib * (rbx * fy - rby * fx);
    }

    if (!a.kinematic) a.rotational_velocity = wa.rad_to_deg();
    if (!b.kinematic) b.rotational_velocity = wb.rad_to_deg();
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
