package util;

class Random {
  /**
   * Takes a minimum and maximum Float and returns a random value bewteen them.
   * Leave blank to return a value between -1 and 1
   * @param	min	Minimum desired result
   * @param	max	Maximum desired result
   */
  public static inline function range(?min:Float = -1, ?max:Float = 1):Float return min + Math.random() * (max - min);

  public static inline function range_int(?min:Float = -1, ?max:Float = 1):Int return Std.int(range(min, max));

  public static inline function range_int_to_string(?min:Float, ?max:Float):String return "" + Math.floor(range_int(min, max));

  public static inline function chance(percent:Float = 50):Bool return Math.random() < percent / 100;
}
