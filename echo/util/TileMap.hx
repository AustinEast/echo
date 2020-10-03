package echo.util;

import echo.Shape;
import echo.data.Options.ShapeOptions;
import echo.shape.Polygon;
import hxmath.math.Vector2;

typedef TileShape = {
  index:Int,
  ?slope_direction:SlopeDirection,
  ?slope_shape:{angle:SlopeAngle, size:SlopeSize},
  ?custom_shape:ShapeOptions
}

enum SlopeDirection {
  TopLeft;
  TopRight;
  BottomLeft;
  BottomRight;
}

enum SlopeAngle {
  Gentle;
  Sharp;
}

enum SlopeSize {
  Thick;
  Thin;
}

class TileMap {
  /**
   * Generates an optimized Array of Bodies from an Array of `Int`s representing a TileMap.
   * @param data The Array of `Int`s that make up the TileMap
   * @param tile_width The Width of each Tile in the TileMap
   * @param tile_height The Height of each Tile in the TileMap
   * @param width_in_tiles The Width of the TileMap (Measured in Tiles)
   * @param height_in_tiles The Height of the TileMap (Measured in Tiles)
   * @param offset_x The Offset applied to the X Position of each generated Body
   * @param offset_y The Offset applied to the Y Position of each generated Body
   * @param start_index The Index that designates which tiles are collidable. Must be larger than -1.
   * @return Array<Body>
   */
  public static function generate(data:Array<Int>, tile_width:Int, tile_height:Int, width_in_tiles:Int, height_in_tiles:Int, offset_x:Float = 0,
      offset_y:Float = 0, start_index:Int = 1, ?shapes:Array<TileShape>, ?ignore:Array<Int>):Array<Body> {
    inline function is_ignored(index:Int):Bool {
      return ignore != null && ignore.indexOf(index) > -1;
    }
    function get_tile_shape(index:Int):Null<TileShape> {
      if (shapes == null || shapes.length == 0) return null;
      for (shape in shapes) {
        if (shape.index == index) return shape;
      }
      return null;
    }
    function generate_shape(x:Int, y:Int, tile_shape:TileShape, data:Array<Array<Int>>):Body {
      // TODO - generate slopes and custom shapes
      data[y][x] = -1;
      var shape:Shape = null;
      if (tile_shape.custom_shape != null) {
        shape = Shape.get(tile_shape.custom_shape);
      }
      else if (tile_shape.slope_direction != null) {
        switch tile_shape.slope_direction {
          case TopLeft:
            if (tile_shape.slope_shape != null) {
              shape = switch tile_shape.slope_shape.angle {
                case Gentle:
                  switch tile_shape.slope_shape.size {
                    case Thick:
                      Polygon.get_from_vertices(0, 0, 0, [
                        new Vector2(0, tile_height * 0.5),
                        new Vector2(tile_width, 0),
                        new Vector2(tile_width, tile_height),
                        new Vector2(0, tile_height)
                      ]);
                    case Thin:
                      Polygon.get_from_vertices(0, 0, 0, [
                        new Vector2(tile_width, tile_height * 0.5),
                        new Vector2(tile_width, tile_height),
                        new Vector2(0, tile_height)
                      ]);
                  }
                case Sharp:
                  switch tile_shape.slope_shape.size {
                    case Thick:
                      Polygon.get_from_vertices(0, 0, 0, [
                        new Vector2(tile_width * 0.5, 0),
                        new Vector2(tile_width, 0),
                        new Vector2(tile_width, tile_height),
                        new Vector2(0, tile_height)
                      ]);
                    case Thin:
                      Polygon.get_from_vertices(0, 0, 0, [
                        new Vector2(tile_width, 0),
                        new Vector2(tile_width, tile_height),
                        new Vector2(tile_width * 0.5, tile_height)
                      ]);
                  }
              }
            }
            else {
              shape = Polygon.get_from_vertices(0, 0, 0, [
                new Vector2(tile_width, 0),
                new Vector2(tile_width, tile_height),
                new Vector2(0, tile_height)
              ]);
            }
          case TopRight:
            if (tile_shape.slope_shape != null) {
              shape = switch tile_shape.slope_shape.angle {
                case Gentle:
                  switch tile_shape.slope_shape.size {
                    case Thick:
                      Polygon.get_from_vertices(0, 0, 0, [
                        new Vector2(0, 0),
                        new Vector2(tile_width, tile_height * 0.5),
                        new Vector2(tile_width, tile_height),
                        new Vector2(0, tile_height)
                      ]);
                    case Thin:
                      Polygon.get_from_vertices(0, 0, 0, [
                        new Vector2(0, tile_height * 0.5),
                        new Vector2(tile_width, tile_height),
                        new Vector2(0, tile_height)
                      ]);
                  }
                case Sharp:
                  switch tile_shape.slope_shape.size {
                    case Thick:
                      Polygon.get_from_vertices(0, 0, 0, [
                        new Vector2(0, 0),
                        new Vector2(tile_width * 0.5, 0),
                        new Vector2(tile_width, tile_height),
                        new Vector2(0, tile_height)
                      ]);
                    case Thin:
                      Polygon.get_from_vertices(0, 0, 0, [
                        new Vector2(0, 0),
                        new Vector2(tile_width * 0.5, tile_height),
                        new Vector2(0, tile_height)
                      ]);
                  }
              }
            }
            else {
              shape = Polygon.get_from_vertices(0, 0, 0, [
                new Vector2(0, 0),
                new Vector2(tile_width, tile_height),
                new Vector2(0, tile_height)
              ]);
            }
          case BottomLeft:
            if (tile_shape.slope_shape != null) {
              shape = switch tile_shape.slope_shape.angle {
                case Gentle:
                  switch tile_shape.slope_shape.size {
                    case Thick:
                      Polygon.get_from_vertices(0, 0, 0, [
                        new Vector2(0, 0),
                        new Vector2(tile_width, 0),
                        new Vector2(tile_width, tile_height),
                        new Vector2(0, tile_height * 0.5)
                      ]);
                    case Thin:
                      Polygon.get_from_vertices(0, 0, 0, [
                        new Vector2(0, 0),
                        new Vector2(tile_width, 0),
                        new Vector2(tile_width, tile_height * 0.5)
                      ]);
                  }
                case Sharp:
                  switch tile_shape.slope_shape.size {
                    case Thick:
                      Polygon.get_from_vertices(0, 0, 0, [
                        new Vector2(0, 0),
                        new Vector2(tile_width, 0),
                        new Vector2(tile_width, tile_height),
                        new Vector2(tile_width * 0.5, tile_height),
                      ]);
                    case Thin:
                      Polygon.get_from_vertices(0, 0, 0, [
                        new Vector2(tile_width * 0.5, 0),
                        new Vector2(tile_width, 0),
                        new Vector2(tile_width, tile_height)
                      ]);
                  }
              }
            }
            else {
              shape = Polygon.get_from_vertices(0, 0, 0, [
                new Vector2(0, 0),
                new Vector2(tile_width, 0),
                new Vector2(tile_width, tile_height)
              ]);
            }
          case BottomRight:
            if (tile_shape.slope_shape != null) {
              shape = switch tile_shape.slope_shape.angle {
                case Gentle:
                  switch tile_shape.slope_shape.size {
                    case Thick:
                      Polygon.get_from_vertices(0, 0, 0, [
                        new Vector2(0, 0),
                        new Vector2(tile_width, 0),
                        new Vector2(tile_width, tile_height * 0.5),
                        new Vector2(0, tile_height)
                      ]);
                    case Thin:
                      Polygon.get_from_vertices(0, 0, 0, [new Vector2(0, 0), new Vector2(tile_width, 0), new Vector2(0, tile_height * 0.5)]);
                  }
                case Sharp:
                  switch tile_shape.slope_shape.size {
                    case Thick:
                      Polygon.get_from_vertices(0, 0, 0, [
                        new Vector2(0, 0),
                        new Vector2(tile_width, 0),
                        new Vector2(tile_width * 0.5, tile_height),
                        new Vector2(0, tile_height)
                      ]);
                    case Thin:
                      Polygon.get_from_vertices(0, 0, 0, [new Vector2(0, 0), new Vector2(tile_width * 0.5, 0), new Vector2(0, tile_height)]);
                  }
              }
            }
            else {
              shape = Polygon.get_from_vertices(0, 0, 0, [new Vector2(0, 0), new Vector2(tile_width, 0), new Vector2(0, tile_height)]);
            }
        }
      }

      return new Body({
        x: x * tile_width + offset_x,
        y: y * tile_height + offset_y,
        mass: 0,
        shape_instance: shape
      });
    }
    function generate_rect(x:Int, y:Int, data:Array<Array<Int>>):Body {
      data[y][x] = -1;
      var width:Int = 1;
      // scan to the right to see how wide the rect should be
      for (i in x + 1...data[y].length) {
        var index = data[y][i];
        if (index >= start_index && get_tile_shape(index) == null && !is_ignored(index)) {
          width++;
          data[y][i] = -1;
        }
        else break;
      }

      var yy = y + 1;
      var height = 1;
      var flag = false;
      // scan down to check how many rows this rectangle can fill
      while (yy < data.length - 1) {
        if (flag) {
          yy = data.length;
          continue;
        }
        for (j in 0...width) {
          var next = data[yy][j + x];
          if (get_tile_shape(next) != null || next < start_index || is_ignored(next)) flag = true;
        }
        if (!flag) {
          for (j in 0...width) {
            data[yy][j + x] = -1;
          }
          height++;
        }
        yy++;
      }
      return new Body({
        x: x * tile_width + ((tile_width * width) * 0.5) + offset_x,
        y: y * tile_height + (tile_height * height * 0.5) + offset_y,
        mass: 0,
        shape: {
          type: RECT,
          width: tile_width * width,
          height: tile_height * height
        }
      });
    }

    var colliders = [];
    var tmp = new Array<Array<Int>>();
    for (i in 0...data.length) {
      var x = i % width_in_tiles;
      var y = Math.floor(i / width_in_tiles);
      if (tmp[y] == null) tmp[y] = [];
      tmp[y][x] = data[i];
    }
    for (y in 0...tmp.length) {
      for (x in 0...tmp[y].length) {
        var i = tmp[y][x];
        if (i >= start_index && !is_ignored(i)) {
          var shape = get_tile_shape(i);
          var body = shape == null ? generate_rect(x, y, tmp) : generate_shape(x, y, shape, tmp);
          body.data.tile_index = shape == null ? start_index : i;
          colliders.push(body);
        }
      }
    }
    return colliders;
  }
  /**
   * Generates an Array of Bodies from an Array of `Int`s representing a TileMap.
   * @param data The Array of `Int`s that make up the TileMap
   * @param tile_width The Width of each Tile in the TileMap
   * @param tile_height The Height of each Tile in the TileMap
   * @param width_in_tiles The Width of the TileMap (Measured in Tiles)
   * @param height_in_tiles The Height of the TileMap (Measured in Tiles)
   * @param offset_x The Offset applied to the X Position of each generated Body
   * @param offset_y The Offset applied to the Y Position of each generated Body
   * @param start_index The Index that designates which tiles are collidable
   * @return Array<Body>
   */
  public static function generate_grid(data:Array<Int>, tile_width:Int, tile_height:Int, width_in_tiles:Int, height_in_tiles:Int, offset_x:Float = 0,
      offset_y:Float = 0, start_index:Int = 1):Array<Body> {
    var colliders = [];
    for (i in 0...data.length) {
      var index = data[i];
      if (index != -1 && index >= start_index) {
        var b = new Body({
          x: (i % width_in_tiles) * tile_width,
          y: Math.floor(i / width_in_tiles) * tile_height,
          mass: 0,
          shape: {
            type: RECT,
            width: tile_width,
            height: tile_height,
            offset_x: tile_width * 0.5 + offset_x,
            offset_y: tile_height * 0.5 + offset_y
          }
        });
        colliders.push(b);
      }
    }
    return colliders;
  }
}
