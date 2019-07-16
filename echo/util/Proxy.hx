package echo.util;

import haxe.macro.Context;
import haxe.macro.Expr;

using Lambda;
/**
 *	Implementing this interface on a Class will run `Proxy.build`, then remove itself.
**/
@:remove
@:autoBuild(ghost.Proxy.build())
interface IProxy {}

class Proxy {
  #if macro
  /**
   * Generates Getters and Setters for all Fields that are marked as such:
   * ```
   * var example(get, set):Bool;
   * ```
   *
   * If a field has the `@:alias` metadata, it will generate Getters and Setters that get/set the value that is passed into the metadata:
   * ```
   * @:alias(position.x)
   * var x(get, set):Float;
   * ```
   *
   * @return Array<Field>
   */
  public static function build():Array<Field> {
    var fields = Context.getBuildFields();
    var append = [];

    for (field in fields) {
      var alias:Null<Expr>;
      if (field.meta != null) {
        for (meta in field.meta) {
          if (meta.name == ':alias') {
            if (meta.params.length > 0) alias = meta.params[0];
            else throw "Variables with the `@:alias` metadata need a property as the parameter";
          }
        }
      }
      switch (field.kind) {
        case FVar(t, e):
          if (alias != null) {
            field.kind = FProp('get', 'set', t, e);
            if (!fields.exists((f) -> return f.name == 'get_${field.name}')) append.push(getter(field.name, alias));
            if (!fields.exists((f) -> return f.name == 'set_${field.name}')) append.push(setter(field.name, alias));
          }
        case FProp(pget, pset, _, _):
          if (pget == 'get' && !fields.exists((f) -> return f.name == 'get_${field.name}')) {
            append.push(getter(field.name, alias));
          }
          if (pset == 'set' && !fields.exists((f) -> return f.name == 'set_${field.name}')) {
            append.push(setter(field.name, alias));
          }
          // Add isVar metadata if needed
          if (pget == 'get' && pset == 'set') {
            if (field.meta != null
              && !field.meta.exists((m) -> return m.name == ':isVar')) field.meta.push({name: ':isVar', pos: Context.currentPos()});
            else if (field.meta == null) field.meta = [{name: ':isVar', pos: Context.currentPos()}];
          }
        default:
      }
    }

    return fields.concat(append);
  }
  /**
   * TODO
   * @return Array<Field>
   */
  public static function options():Array<Field> {
    var local_class = Context.getLocalClass().get();
    var fields = Context.getBuildFields();
    var defaults = fields.filter((f) -> {
      for (m in f.meta) if (m.name == ':defaultOp') return true;
      return false;
    });

    Context.defineType({
      pos: Context.currentPos(),
      name: '${local_class.name}Options',
      fields: defaults,
      pack: local_class.pack,
      kind: TDStructure
    });

    if (defaults.length == 0) return fields;

    // fields.push({
    //   name: 'defaults',
    //   kind:
    // });

    for (f in fields) {}

    return fields;
  }
  /**
   * Generates a Getter function for a value
   * @param name name of the var (`x` will return `get_x`)
   * @param alias optional field that the getter will get instead
   */
  static function getter(name:String, ?alias:Expr):Field return {
    name: 'get_${name}',
    kind: FieldType.FFun({
      args: [],
      expr: alias != null ? macro return ${alias} : macro return $i{name},
      ret: null
    }),
    pos: Context.currentPos()
  }
  /**
   * Generates a Setter function for a value
   * @param name name of the var (`x` will return `set_x`)
   * @param alias optional field that the setter will set instead
   */
  static function setter(name:String, ?alias:Expr):Field return {
    name: 'set_${name}',
    kind: FieldType.FFun({
      args: [{name: 'value', type: null}],
      expr: alias != null ? macro return ${alias} = value : macro return $i{name} = value,
      ret: null
    }),
    pos: Context.currentPos()
  }
  #end
}
