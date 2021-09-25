package echo.util.ext;

inline function max(a:Int, b:Int):Int {
  return b > a ? b : a;
}

inline function min(a:Int, b:Int):Int {
  return b < a ? b : a;
}
