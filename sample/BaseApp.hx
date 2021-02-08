package;

import echo.World;
import echo.util.Debug;
import util.FSM;

class BaseApp extends hxd.App {
  public var debug:HeapsDebug;

  var sample_states:Array<Class<State<World>>>;
  var fsm:FSM<World>;
  var fui:h2d.Flow;
  var index:Int = 0;

  function reset_state() return fsm.set(Type.createInstance(sample_states[index], []));

  function previous_state() {
    index -= 1;
    if (index < 0) index = sample_states.length - 1;
    return fsm.set(Type.createInstance(sample_states[index], []));
  }

  function next_state() {
    index += 1;
    if (index >= sample_states.length) index = 0;
    return fsm.set(Type.createInstance(sample_states[index], []));
  }

  public function getFont() {
    return hxd.res.DefaultFont.get();
  }

  public function addButton(label:String, onClick:Void->Void, ?parent:h2d.Object) {
    var f = new h2d.Flow(parent == null ? fui : parent);
    f.padding = 5;
    f.paddingBottom = 7;
    f.backgroundTile = h2d.Tile.fromColor(0x404040, 1, 1, 0.5);
    var tf = new h2d.Text(getFont(), f);
    tf.text = label;
    f.enableInteractive = true;
    f.interactive.cursor = Button;
    f.interactive.onClick = function(_) onClick();
    f.interactive.onOver = function(_) f.backgroundTile = h2d.Tile.fromColor(0x606060, 1, 1, 0.5);
    f.interactive.onOut = function(_) f.backgroundTile = h2d.Tile.fromColor(0x404040, 1, 1, 0.5);
    return f;
  }

  public function addSlider(label:String, get:Void->Float, set:Float->Void, min:Float = 0., max:Float = 1., int:Bool = false) {
    var f = new h2d.Flow(fui);

    f.horizontalSpacing = 5;

    var tf = new h2d.Text(getFont(), f);
    tf.text = label;
    tf.maxWidth = 70;
    tf.textAlign = Right;

    var sli = new h2d.Slider(100, 10, f);
    sli.minValue = min;
    sli.maxValue = max;
    sli.value = get();

    var tf = new h2d.TextInput(getFont(), f);
    tf.text = "" + (int ? Std.int(hxd.Math.fmt(sli.value)) : hxd.Math.fmt(sli.value));
    sli.onChange = function() {
      set(sli.value);
      tf.text = "" + (int ? Std.int(hxd.Math.fmt(sli.value)) : hxd.Math.fmt(sli.value));
      f.needReflow = true;
    };
    tf.onChange = function() {
      var v = Std.parseFloat(tf.text);
      if (Math.isNaN(v)) return;
      sli.value = v;
      set(v);
    };
    return sli;
  }

  public function addCheck(label:String, get:Void->Bool, set:Bool->Void) {
    var f = new h2d.Flow(fui);

    f.horizontalSpacing = 5;

    var tf = new h2d.Text(getFont(), f);
    tf.text = label;
    tf.maxWidth = 70;
    tf.textAlign = Right;

    var size = 10;
    var b = new h2d.Graphics(f);
    function redraw() {
      b.clear();
      b.beginFill(0x808080);
      b.drawRect(0, 0, size, size);
      b.beginFill(0);
      b.drawRect(1, 1, size - 2, size - 2);
      if (get()) {
        b.beginFill(0xC0C0C0);
        b.drawRect(2, 2, size - 4, size - 4);
      }
    }
    var i = new h2d.Interactive(size, size, b);
    i.onClick = function(_) {
      set(!get());
      redraw();
    };
    redraw();
    return i;
  }

  public function addChoice(text, choices, callb:Int->Void, value = 0, width = 110) {
    var font = getFont();
    var i = new h2d.Interactive(width, font.lineHeight, fui);
    i.backgroundColor = 0xFF808080;
    fui.getProperties(i).paddingLeft = 20;

    var t = new h2d.Text(font, i);
    t.maxWidth = i.width;
    t.text = text + ":" + choices[value];
    t.textAlign = Center;

    i.onClick = function(_) {
      value++;
      value %= choices.length;
      callb(value);
      t.text = text + ":" + choices[value];
    };
    i.onOver = function(_) {
      t.textColor = 0xFFFFFF;
    };
    i.onOut = function(_) {
      t.textColor = 0xEEEEEE;
    };
    i.onOut(null);
    return i;
  }

  public function addText(text = "", ?parent) {
    var tf = new h2d.Text(getFont(), parent == null ? fui : parent);
    tf.text = text;
    return tf;
  }
}
