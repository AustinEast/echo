package echo.util.ext;

inline function dispose_bodies(arr:Array<Body>):Array<Body> {
  for (body in arr) body.dispose();
  return arr;
}
