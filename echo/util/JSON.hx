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
  public static function copy_fields<T>(from:T, into:T):T {
    if (from == null) return into;
    if (into == null) into = Reflect.copy(from);
    else for (f in Reflect.fields(from)) Reflect.setField(into, f, Reflect.field(from, f));

    return into;
  }
}
