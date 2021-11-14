package echo.util.ext;

inline function max(a:Int, b:Int):Int {
  return b > a ? b : a;
}

inline function min(a:Int, b:Int):Int {
  return b < a ? b : a;
}

inline extern overload function sign(value:Int):Int return value > 0 ? 1 : value < 0 ? -1 : 0;

inline extern overload function sign(value:Int, deadzone:Int):Int {
  if (Math.abs(value) < deadzone) return 0;
  return value <= -deadzone ? -1 : 1;
}
