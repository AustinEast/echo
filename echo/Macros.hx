package echo;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;

class Macros {
  static var dataFields:Array<Field> = [];

  static function build_body() {
    if (dataFields.length == 0) return null;
    var fields = Context.getBuildFields();
    for (f in dataFields) fields.push(f);
    return fields;
  }
  /**
   * Build Macro to add extra fields to the Body class. Inspired by [@Yanrishatum](https://github.com/Yanrishatum).
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
}
#end
