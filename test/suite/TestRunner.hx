package suite;

import suite.Test.*;

/**
 * Runs the whole test suite. Build and run with `haxe test-suite.hxml`.
 */
class TestRunner {
  static function main() {
    BroadphaseTest.run();
    FullPhysicsTest.run();
    VerletTest.run();
    RaycastTest.run();
    DecomposeTest.run();
    finish();
  }
}
