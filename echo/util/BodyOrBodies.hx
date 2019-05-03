package echo.util;

import haxe.ds.Either;

abstract BodyOrBodies(Either<Body, Array<Body>>) from Either<Body, Array<Body>> to Either<Body, Array<Body>> {
  @:from inline static function from_body(a:Body):BodyOrBodies {
    return Left(a);
  }

  @:from inline static function from_bodies(b:Array<Body>):BodyOrBodies {
    return Right(b);
  }

  @:to inline function to_body():Null<Body> return switch (this) {
    case Left(a): a;
    default: null;
  }

  @:to inline function to_bodies():Null<Array<Body>> return switch (this) {
    case Right(b): b;
    default: null;
  }
}
