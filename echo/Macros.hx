package echo;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;

class Macros {
  static var dataFields:Map<String, String> = [];

  static function build_body() {
    if (Lambda.count(dataFields) == 0) return null;
    var fields = Context.getBuildFields();
    for (kv in dataFields.keyValueIterator()) {
      fields.push({
        name: kv.key,
        access: [Access.APublic],
        kind: FieldType.FVar(Context.toComplexType(Context.getType(kv.value))),
        pos: Context.currentPos()
      });
    }
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
    dataFields[name] = type;
  }
}
#end
