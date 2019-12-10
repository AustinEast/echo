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
