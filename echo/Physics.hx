package echo;

class Physics {
  public static function step() {
    // Integrate
  }
  // public static function resolve(e1:CollisionItem, e2:CollisionItem, cd:CollisionData) {
  //   // Calculate relative velocity
  //   var rv = e1.motion.velocity - e2.motion.velocity;
  //   // Calculate relative velocity in terms of the normal direction
  //   var vel_to_normal = rv * cd.normal;
  //   var inv_mass_sum = e1.motion.inv_mass + e2.motion.inv_mass;
  //   // Do not resolve if velocities are separating
  //   if (vel_to_normal > 0) {
  //     // Calculate elasticity
  //     var e = (e1.motion.elasticity + e2.motion.elasticity) * 0.5;
  //     // Calculate impulse scalar
  //     var j = (-(1 + e) * vel_to_normal) / inv_mass_sum;
  //     var impulse = -j * cd.normal;
  //     // Apply impulse
  //     var mass_sum = e1.motion.mass + e2.motion.mass;
  //     var ratio = e1.motion.mass / mass_sum;
  //     e1.motion.velocity -= impulse * e1.motion.inv_mass;
  //     ratio = e2.motion.mass / mass_sum;
  //     e2.motion.velocity += impulse * e2.motion.inv_mass;
  //   }
  //   var correction = (Math.max(cd.overlap - lerp, 0) / inv_mass_sum) * correction_percent * cd.normal;
  //   e1.transform.subtract(e1.motion.inv_mass * correction);
  //   e2.transform.add(e2.motion.inv_mass * correction);
  // }
  // public static function resolve_static(e:CollisionItem, cd:CollisionData) {
  //   var vel_to_normal = e.motion.velocity * cd.normal;
  //   if (vel_to_normal > 0) {
  //     var j = (-(1 + e.motion.elasticity) * vel_to_normal) / e.motion.inv_mass;
  //     var impulse = -j * cd.normal;
  //     // Apply impulse
  //     e.motion.velocity -= impulse * e.motion.inv_mass;
  //   }
  //   var correction = (Math.max(cd.overlap - lerp, 0) / e.motion.inv_mass) * correction_percent * cd.normal;
  //   e.transform.subtract(e.motion.inv_mass * correction);
  // }
  // public static inline function compute_velocity(v:Float, a:Float, d:Float, m:Float) {
  //   // Apply Acceleration to Velocity
  //   if (a != 0) {
  //     v += a;
  //   }
  //   // Otherwise Apply Drag to Velocity
  //   else if (d != 0) {
  //     if (v - d > 0) v -= d;
  //     else if (v + d < 0) v += d;
  //     else v = 0;
  //   }
  //   // Clamp Velocity if it has a Max
  //   if (m != 0) v = v.clamp(-m, m);
  //   return v;
  // }
}
