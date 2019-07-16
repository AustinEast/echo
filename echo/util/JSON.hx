package echo.util;

/**
 * Class to provide different Utilities for dealing with Object Data
 */
class JSON {
  /**
   * Copy an object's fields into target object. Overwrites the target object's fields.
   * Can work with Static Classes as well (as destination)
   *
   * Adapted from the DJFlixel Library: https://github.com/johndimi/djFlixel
   *
   * @param	from The Master object to copy fields from
   * @param	into The Target object to copy fields to
   * @return	The resulting object
   */
  public static function copy_fields(from:Dynamic, into:Dynamic):Dynamic {
    if (from == null) return into;
    if (into == null) into = Reflect.copy(from);
    else for (f in Reflect.fields(from)) Reflect.setField(into, f, Reflect.field(from, f));

    return into;
  }
  /**
   * Copy All Fields AND translates colors. Overwrites the target object's fields.
   *
   * - If a field starts with "color" it will automatically convert it to proper INT
   *    e.g. "0xffffff" or "blue" => (int)0x0000FF
   *
   * Adapted from the DJFlixel Library: https://github.com/johndimi/djFlixel
   *
   * @param	from The Source Object to copy fields from
   * @param	into The Destination object, if null it will be created. It is altered in place
   * @return  The resulting object
   */
  public static function copy_fields_c(from:Dynamic, ?into:Dynamic):Dynamic {
    if (into == null) into = {};
    if (from != null) for (f in Reflect.fields(from)) {
      var d:Dynamic = Reflect.field(from, f);

      // f is the name of the field
      // d is the field data

      // Convert COLOR string and array of strings to INT
      if (f.indexOf("color") == 0) {
        if (Std.is(d, String)) {
          Reflect.setField(into, f, ghost.Color.fromString(d));
          continue;
        }
      }

      // Process any object nodes
      if (Reflect.isObject(d) && !Std.is(d, Array) && !Std.is(d, String)) {
        if (!Reflect.hasField(into, f)) Reflect.setField(into, f, {});
        copy_fields(d, Reflect.field(into, f));
        continue;
      }

      // Just copy everything else.
      Reflect.setField(into, f, Reflect.field(from, f));
    }

    return into;
  }
}
