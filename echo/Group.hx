package echo;

import glib.Disposable;

class Group implements IDisposable {
  public var members:Array<Body>;

  public function new(?members:Array<Body>) {
    this.members = members == null ? [] : members;
  }

  public function add(body:Body):Body {
    members.remove(body);
    members.push(body);
    return body;
  }

  public function remove(body:Body):Body {
    members.remove(body);
    return body;
  }

  public function dispose() {
    members = null;
  }
}
