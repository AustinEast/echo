package echo.util;

import glib.Pool;
import echo.Body;
import echo.Shape;
import echo.shape.Rect;
/**
 * Simple QuadTree implementation to assist with broad-phase 2D collisions.
 *
 * TODO: Doc this boi up!
 */
class QuadTree extends Rect implements IPooled {
  public static var max_depth:Int = 5;
  public static var max_objects:Int = 5;
  public static var pool(get, never):IPool<QuadTree>;
  static var _pool = new Pool<QuadTree>(QuadTree);

  public var children:Array<QuadTree>;
  public var contents:Array<QuadTreeData>;
  public var count(get, null):Int;
  public var leaf(get, null):Bool;
  public var depth:Int;

  function new(?rect:Rect, depth:Int = 0) {
    super();
    if (rect != null) load(rect);
    this.depth = depth;
    children = [];
    contents = [];
  }

  public static inline function get(x:Float = 0, y:Float = 0, width:Float = 0, height:Float = 0):QuadTree {
    var qt = _pool.get();
    qt.set(x, y, width, height);
    qt.clear_children();
    qt.pooled = false;
    return qt;
  }

  override function put() {
    if (!pooled) {
      pooled = true;
      for (child in children) child.put();
      children = [];
      contents = [];
      _pool.put_unsafe(this);
    }
  }

  public function insert(data:QuadTreeData) {
    // If the new data does not intersect this node, stop.
    if (!data.bounds.overlaps(this)) return;
    // If the node is a leaf and contains more than the maximum allowed, split it.
    if (leaf && contents.length + 1 > max_objects) split();
    // If the node is still a leaf, push the data to it.
    // Else try to insert the data into the node's children
    if (leaf) contents.push(data);
    else for (child in children) child.insert(data);
  }

  public function remove(data:QuadTreeData) {
    leaf ? contents.remove(data) : for (child in children) child.remove(data);
    shake();
  }

  public function update(data:QuadTreeData) {
    remove(data);
    insert(data);
  }

  public function query(shape:Shape):Array<QuadTreeData> {
    var result:Array<QuadTreeData> = [];
    if (!overlaps(shape)) return result;
    if (leaf) {
      for (data in contents) if (data.bounds.overlaps(shape)) result.push(data);
    }
    else {
      for (child in children) {
        var recurse = child.query(shape);
        if (recurse.length > 0) {
          result = result.concat(recurse);
        }
      }
    }

    return result;
  }

  function shake() {
    if (!leaf) {
      var len = count;
      if (len == 0) {
        clear_children();
      }
      else if (len < max_objects) {
        var nodes = new List<QuadTree>();
        nodes.push(this);
        while (nodes.length > 0) {
          var node = nodes.first();
          if (node.leaf) {
            for (data in node.contents) {
              if (contents.indexOf(data) == -1) contents.push(data);
            }
          }
          else for (child in node.children) nodes.add(child);
          nodes.pop();
        }
        clear_children();
      }
    }
  }

  function split() {
    if (depth + 1 >= max_depth) return;

    var xw = ex * 0.5;
    var xh = ey * 0.5;

    for (i in 0...4) {
      switch (i) {
        case 0:
          children.push(get(x - xw, y - xh, ex, ey));
        case 1:
          children.push(get(x + xw, y - xh, ex, ey));
        case 2:
          children.push(get(x - xw, y + xh, ex, ey));
        case 3:
          children.push(get(x + xw, y + xh, ex, ey));
      }
      children[i].depth = depth + 1;
      for (j in 0...contents.length) {
        children[i].insert(contents[j]);
      }
    }
    contents = [];
  }

  function reset() {
    if (leaf) for (data in contents) data.flag = false;
    else for (child in children) child.reset();
  }

  function clear_children() {
    for (child in children) {
      child.contents.resize(0);
      child.clear_children();
      child.put();
    }
    children.resize(0);
  }

  function get_count() {
    reset();
    // Initialize the count with this node's content's length
    var num = 0;
    for (data in contents) {
      data.flag = true;
      num += 1;
    }

    // Create a list of nodes to process and push the current tree to it.
    var nodes = new List<QuadTree>();
    nodes.push(this);

    // Process the nodes.
    // While there still nodes to process, grab the last node in the list.
    // If the node is a leaf, add all its contents to the count.
    // Else push this node's children to the end of the node list.
    // Finally, remove the node from the list.
    while (nodes.length > 0) {
      var node = nodes.first();
      if (node.leaf) {
        for (data in node.contents) {
          if (!data.flag) {
            num += 1;
            data.flag = true;
          }
        }
      }
      else for (child in node.children) nodes.add(child);
      nodes.pop();
    }
    reset();
    return num;
  }

  function get_leaf() return children.length == 0;

  static function get_pool():IPool<QuadTree> return _pool;
}

typedef QuadTreeData = TypedQuadTreeData<Dynamic>;

typedef TypedQuadTreeData<T> = {
  /**
   * Data to store.
   */
  var ?data:T;
  var ?body:Body;
  /**
   * Bounds of the Data.
   */
  var bounds:Rect;
  /**
   * Helper flag to check if this Data has been counted during queries.
   */
  var flag:Bool;
}
