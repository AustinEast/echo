package echo.util;

class Ext {
  public static inline function equals(a:Float, b:Float, diff:Float = 0.00001):Bool {
    return Math.abs(a - b) <= diff;
  }
}
