package echo.util;

import echo.util.Pool;
import echo.Body;
import echo.Shape;
import echo.shape.Rect;
import echo.data.Data;
/**
 * Simple QuadTree implementation to assist with broad-phase 2D collisions.
 */
class QuadTree extends AABB implements IPooled {
  public static var pool(get, never):IPool<QuadTree>;
  static var _pool = new Pool<QuadTree>(QuadTree);
  /**
   * The maximum branch depth for this QuadTree collection. Once the max depth is reached, the QuadTrees at the end of the collection will not spilt.
   */
  public var max_depth(default, set):Int = 5;
  /**
   * The maximum amount of `QuadTreeData` contents that a QuadTree `leaf` can hold before becoming a branch and splitting it's contents between children Quadtrees.
   */
  public var max_contents(default, set):Int = 10;
  /**
   * The child QuadTrees contained in the Quadtree. If this Array is empty, the Quadtree is regarded as a `leaf`.
   */
  public var children:Array<QuadTree>;
  /**
   * The QuadTreeData contained in the Quadtree. If the Quadtree is not a `leaf`, all of it's contents will be dispersed to it's children QuadTrees (leaving this aryar emyty).
   */
  public var contents:Array<QuadTreeData>;
  /**
   * Gets the total amount of `QuadTreeData` contents in the Quadtree, recursively. To get the non-recursive amount, check `quadtree.contents.length`.
   */
  public var count(get, null):Int;
  /**
   * A QuadTree is regarded as a `leaf` if it has **no** QuadTree children (ie `quadtree.children.length == 0`).
   */
  public var leaf(get, null):Bool;
  /**
   * The QuadTree's branch position in it's collection.
   */
  public var depth:Int;
  /**
   * Cache'd list of QuadTrees used to help with memory management.
   */
  var nodes_list:Array<QuadTree> = [];

  function new(?aabb:AABB, depth:Int = 0) {
    super();
    if (aabb != null) load(aabb);
    this.depth = depth;
    children = [];
    contents = [];
  }
  /**
   * Gets a QuadTree from the pool of available Quadtrees (or creates one if none are available), and sets it with the provided values.
   */
  public static inline function get(x:Float = 0, y:Float = 0, width:Float = 0, height:Float = 0):QuadTree {
    var qt = _pool.get();
    qt.set(x, y, width, height);
    qt.clear_children();
    qt.pooled = false;
    return qt;
  }
  /**
   * Puts the QuadTree back in the pool of available QuadTrees.
   */
  override inline function put() {
    if (!pooled) {
      pooled = true;
      for (child in children) child.put();
      children.resize(0);
      contents.resize(0);
      nodes_list.resize(0);
      _pool.put_unsafe(this);
    }
  }
  /**
   * Attempts to insert the `QuadTreeData` into the QuadTree. If the `QuadTreeData` already exists in the QuadTree, use `quadtree.update(data)` instead.
   */
  public function insert(data:QuadTreeData) {
    if (data.bounds == null) return;
    // If the new data does not intersect this node, stop.
    if (!data.bounds.overlaps(this)) return;
    // If the node is a leaf and contains more than the maximum allowed, split it.
    if (leaf && contents.length + 1 > max_contents) split();
    // If the node is still a leaf, push the data to it.
    // Else try to insert the data into the node's children
    if (leaf) contents.push(data);
    else for (child in children) child.insert(data);
  }
  /**
   * Attempts to remove the `QuadTreeData` from the QuadTree.
   */
  public function remove(data:QuadTreeData):Bool {
    if (leaf) return contents.remove(data);

    var removed = false;
    for (child in children) if (child.remove(data)) removed = true;
    if (removed) shake();

    return removed;
  }
  /**
   * Updates the `QuadTreeData` in the QuadTree by first removing the `QuadTreeData` from the QuadTree, then inserting it.
   * @param data
   */
  public function update(data:QuadTreeData) {
    remove(data);
    insert(data);
  }
  /**
   * Queries the QuadTree for any `QuadTreeData` that overlaps the `AABB`.
   * @param aabb The `AABB` to query.
   * @param result An Array containing all `QuadTreeData` that collides with the shape.
   */
  public function query(aabb:AABB, result:Array<QuadTreeData>) {
    if (!overlaps(aabb)) {
      return;
    }
    if (leaf) {
      for (data in contents) if (data.bounds.overlaps(aabb)) result.push(data);
    }
    else {
      for (child in children) child.query(aabb, result);
    }
  }
  /**
   * If the QuadTree is a branch (_not_ a `leaf`), this will check if the amount of data from all the child Quadtrees can fit in the Quadtree without exceeding it's `max_contents`.
   * If all the data can fit, the Quadtree branch will "shake" its child Quadtrees, absorbing all the data and clearing the children (putting all the child Quadtrees back in the pool).
   *
   * Note - This works recursively.
   */
  public function shake() {
    if (!leaf) {
      var len = count;
      if (len == 0) {
        clear_children();
      }
      else if (len < max_contents) {
        nodes_list.resize(0);
        nodes_list.push(this);
        while (nodes_list.length > 0) {
          var node = nodes_list.shift();
          if (node != this && node.leaf) {
            for (data in node.contents) {
              if (contents.indexOf(data) == -1) contents.push(data);
            }
          }
          else for (child in node.children) nodes_list.push(child);
        }
        clear_children();
      }
    }
  }
  /**
   * Splits the Quadtree into 4 Quadtree children, and disperses it's `QuadTreeData` contents into them.
   */
  function split() {
    if (depth + 1 >= max_depth) return;

    var xw = width * 0.5;
    var xh = height * 0.5;

    for (i in 0...4) {
      var child = get();
      switch (i) {
        case 0:
          child.set_from_min_max(min_x, min_y, min_x + xw, min_y + xh);
        case 1:
          child.set_from_min_max(min_x + xw, min_y, max_x, min_y + xh);
        case 2:
          child.set_from_min_max(min_x, min_y + xh, min_x + xw, max_y);
        case 3:
          child.set_from_min_max(min_x + xw, min_y + xh, max_x, max_y);
      }
      child.depth = depth + 1;
      child.max_depth = max_depth;
      child.max_contents = max_contents;
      for (j in 0...contents.length) child.insert(contents[j]);
      children.push(child);
    }
    contents.resize(0);
  }
  /**
   * Clears the Quadtree's `QuadTreeData` contents and all children Quadtrees.
   */
  public inline function clear() {
    clear_children();
    contents.resize(0);
  }
  /**
   * Puts all of the Quadtree's children back in the pool and clears the `children` Array.
   */
  inline function clear_children() {
    for (i in 0...children.length) {
      children[i].clear_children();
      children[i].put();
    }
    children.resize(0);
  }
  /**
   * Resets the `flag` value of the QuadTree's `QuadTreeData` contents.
   */
  inline function reset_data_flags() {
    if (leaf) for (i in 0...contents.length) contents[i].flag = false;
    else for (i in 0...children.length) children[i].reset_data_flags();
  }

  // getters

  function get_count() {
    reset_data_flags();
    // Initialize the count with this node's content's length
    var num = 0;
    for (data in contents) {
      data.flag = true;
      num += 1;
    }

    // Create a list of nodes to process and push the current tree to it.
    nodes_list.resize(0);
    nodes_list.push(this);

    // Process the nodes.
    // While there still nodes to process, grab the first node in the list.
    // If the node is a leaf, add all its contents to the count.
    // Else push this node's children to the end of the node list.
    // Finally, remove the node from the list.
    while (nodes_list.length > 0) {
      var node = nodes_list.shift();
      if (node.leaf) {
        for (data in node.contents) {
          if (!data.flag) {
            num += 1;
            data.flag = true;
          }
        }
      }
      else for (child in node.children) nodes_list.push(child);
    }
    return num;
  }

  inline function get_leaf() return children.length == 0;

  static inline function get_pool():IPool<QuadTree> return _pool;

  // setters

  inline function set_max_depth(value:Int) {
    for (child in children) child.max_depth = value;
    return max_depth = value;
  }

  inline function set_max_contents(value:Int) {
    for (child in children) child.max_contents = value;
    return max_contents = value;
  }
}
