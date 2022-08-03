package echo.util;

import haxe.ds.Vector;
import echo.data.Data;
import echo.util.Poolable;
/**
 * Simple QuadTree implementation to assist with broad-phase 2D collisions.
 */
class QuadTree extends AABB {
  /**
   * The maximum branch depth for this QuadTree collection. Once the max depth is reached, the QuadTrees at the end of the collection will not spilt.
   */
  public var max_depth(default, set):Int = 5;
  /**
   * The maximum amount of `QuadTreeData` contents that a QuadTree `leaf` can hold before becoming a branch and splitting it's contents between children Quadtrees.
   */
  public var max_contents(default, set):Int = 10;
  /**
   * The child QuadTrees contained in the Quadtree. If this Vector is empty, the Quadtree is regarded as a `leaf`.
   */
  public var children:Vector<QuadTree>;
  /**
   * The QuadTreeData contained in the Quadtree. If the Quadtree is not a `leaf`, all of it's contents will be dispersed to it's children QuadTrees (leaving this aryar emyty).
   */
  public var contents:Array<QuadTreeData>;
  /**
   * Gets the total amount of `QuadTreeData` contents in the Quadtree, recursively. To get the non-recursive amount, check `quadtree.contents_count`.
   */
  public var count(get, null):Int;

  public var contents_count:Int;
  /**
   * A QuadTree is regarded as a `leaf` if it has **no** QuadTree children (ie `quadtree.children.length == 0`).
   */
  public var leaf(get, never):Bool;
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
    children = new Vector(4);
    contents = [];
    contents_count = 0;
  }
  /**
   * Gets an Quadtree from the pool, or creates a new one if none are available. Call `put()` on the Quadtree to place it back in the pool.
   *
   * Note - The X and Y positions represent the center of the Quadtree. To set the Quadtree from its Top-Left origin, `Quadtree.get_from_min_max()` is available.
   * @param x The centered X position of the Quadtree.
   * @param y The centered Y position of the Quadtree.
   * @param width The width of the Quadtree.
   * @param height The height of the Quadtree.
   * @return Quadtree
   */
  public static inline function get(x:Float = 0, y:Float = 0, width:Float = 1, height:Float = 1):QuadTree {
    var qt = pool.get();
    qt.set(x, y, width, height);
    qt.clear();
    qt.pooled = false;
    return qt;
  }
  /**
   * Gets an Quadtree from the pool, or creates a new one if none are available. Call `put()` on the Quadtree to place it back in the pool.
   * @param min_x
   * @param min_y
   * @param max_x
   * @param max_y
   * @return Quadtree
   */
  public static inline function get_from_min_max(min_x:Float, min_y:Float, max_x:Float, max_y:Float):QuadTree {
    var qt = pool.get();
    qt.set_from_min_max(min_x, min_y, max_x, max_y);
    qt.clear();
    qt.pooled = false;
    return qt;
  }
  /**
   * Puts the QuadTree back in the pool of available QuadTrees.
   */
  override inline function put() {
    if (!pooled) {
      pooled = true;
      clear();
      nodes_list.resize(0);
      pool.put_unsafe(this);
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
    if (leaf && contents_count + 1 > max_contents) split();
    // If the node is still a leaf, push the data to it.
    // Else try to insert the data into the node's children
    if (leaf) {
      var index = get_first_null(contents);
      if (index == -1) contents.push(data);
      else contents[index] = data;
      contents_count++;
    }
    else for (child in children) child.insert(data);
  }
  /**
   * Attempts to remove the `QuadTreeData` from the QuadTree.
   */
  public function remove(data:QuadTreeData, allow_shake:Bool = true):Bool {
    if (leaf) {
      var i = 0;
      while (i < contents.length) {
        if (contents[i] != null && data != null && contents[i].id == data.id) {
          contents[i] = null;
          contents_count--;
          return true;
        }
        i++;
      }
      return false;
      // return contents.remove(data);
    }

    var removed = false;
    for (child in children) if (child != null && child.remove(data)) removed = true;
    if (allow_shake && removed) shake();

    return removed;
  }
  /**
   * Updates the `QuadTreeData` in the QuadTree by first removing the `QuadTreeData` from the QuadTree, then inserting it.
   * @param data
   */
  public function update(data:QuadTreeData, allow_shake:Bool = true) {
    remove(data, allow_shake);
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
      for (data in contents) if (data != null && data.bounds.overlaps(aabb)) result.push(data);
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
  public function shake():Bool {
    if (leaf) return false;
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
            if (contents.indexOf(data) == -1) {
              var index = get_first_null(contents);
              if (index == -1) contents.push(data);
              else contents[index] = data;
              contents_count++;
            }
          }
        }
        else for (child in node.children) nodes_list.push(child);
      }
      clear_children();
      return true;
    }
    return false;
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
      for (j in 0...contents.length) if (contents[j] != null) child.insert(contents[j]);
      children[i] = child;
    }

    clear_contents();
  }
  /**
   * Clears the Quadtree's `QuadTreeData` contents and all children Quadtrees.
   */
  public inline function clear() {
    clear_children();
    clear_contents();
  }
  /**
   * Puts all of the Quadtree's children back in the pool and clears the `children` Array.
   */
  inline function clear_children() {
    for (i in 0...children.length) {
      if (children[i] != null) {
        children[i].clear_children();
        children[i].put();
        children[i] = null;
      }
    }
  }

  inline function clear_contents() {
    contents.resize(0);
    contents_count = 0;
  }
  /**
   * Resets the `flag` value of the QuadTree's `QuadTreeData` contents.
   */
  function reset_data_flags() {
    for (i in 0...contents.length) if (contents[i] != null) contents[i].flag = false;
    for (i in 0...children.length) if (children[i] != null) children[i].reset_data_flags();
  }

  // getters

  function get_count() {
    reset_data_flags();
    // Initialize the count with this node's content's length
    var num = 0;
    for (i in 0...contents.length) {
      if (contents[i] != null) {
        contents[i].flag = true;
        num += 1;
      }
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
        for (i in 0...node.contents.length) {
          if (node.contents[i] != null && !node.contents[i].flag) {
            num += 1;
            node.contents[i].flag = true;
          }
        }
      }
      else for (i in 0...node.children.length) nodes_list.push(node.children[i]);
    }
    return num;
  }

  function get_first_null(arr:Array<QuadTreeData>) {
    for (i in 0...arr.length) if (arr[i] == null) return i;
    return -1;
  }

  inline function get_leaf() return children[0] == null;

  // setters

  inline function set_max_depth(value:Int) {
    for (i in 0...children.length) if (children[i] != null) children[i].max_depth = value;
    return max_depth = value;
  }

  inline function set_max_contents(value:Int) {
    for (i in 0...children.length) if (children[i] != null) children[i].max_depth = value;
    max_contents = value;
    shake();
    return max_contents;
  }
}
