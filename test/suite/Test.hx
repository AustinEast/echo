package suite;

/**
 * Minimal assertion helpers shared by the test suite. Works on any `sys` target, and on JS when run with node.
 */
class Test {
  public static var passes = 0;
  public static var failures = 0;

  public static function section(name:String) println(name);
  /**
   * Records a check. Failed checks print their optional `detail` to help diagnose the failure.
   */
  public static function check(name:String, cond:Bool, ?detail:String) {
    if (cond) {
      passes++;
      println('  ok   - $name');
    }
    else {
      failures++;
      println('  FAIL - $name' + (detail == null ? '' : ' ($detail)'));
    }
  }

  public static function approx(a:Float, b:Float, tol:Float = 0.01):Bool return Math.abs(a - b) <= tol;

  public static function println(s:String) {
    #if js
    js.Syntax.code("console.log({0})", s);
    #else
    Sys.println(s);
    #end
  }

  public static function exit(code:Int) {
    #if js
    js.Syntax.code("process.exit({0})", code);
    #else
    Sys.exit(code);
    #end
  }

  public static function args():Array<String> {
    #if js
    return js.Syntax.code("process.argv.slice(2)");
    #else
    return Sys.args();
    #end
  }
  /**
   * Prints the totals and exits with a non-zero code if any check failed.
   */
  public static function finish() {
    println('\n$passes passed, $failures failed');
    exit(failures == 0 ? 0 : 1);
  }
}
