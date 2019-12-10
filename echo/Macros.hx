package echo;

import haxe.macro.Expr;
import haxe.macro.Context;

class Macros {
  #if macro
  static var dataFields:Array<Field> = []; // add fields here

  static function build_body() {
    if (dataFields.length == 0) return null; // No change, more optimal than returning array of fields.
    var fields = Context.getBuildFields();
    for (f in dataFields) fields.push(f);
    return fields;
  }
  /**
   * Build Macro to add extra fields to the body class. Inspired by [@Yanrishatum](https://github.com/Yanrishatum).
   *
   * Example: in build.hxml - `--macro echo.Macros.add_data("entity", "some.package.Entity")
   * @param name
   * @param type
   */
  public static function add_data(name:String, type:String) {
    dataFields.push({
      name: name,
      access: [Access.APublic],
      kind: FieldType.FVar(Context.toComplexType(Context.getType(type))),
      pos: Context.currentPos()
    });
  }
  #end
}
