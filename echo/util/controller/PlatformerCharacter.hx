package echo.util.controller;

class PlatformerCharacter {
  public var controller:CharacterController;

  public function new(x:Float, y:Float, width:Float, height:Float) {
    controller = new CharacterController(x, y, width, height);
  }
}
