package util;

import haxe.io.Path;
/**
 * Macro for copying assets from one folder to another
 */
class Assets {
  #if macro
  private static function copy(sourceDir:String, targetDir:String):Int {
    var numCopied:Int = 0;

    if (!sys.FileSystem.exists(targetDir)) sys.FileSystem.createDirectory(targetDir);

    for (entry in sys.FileSystem.readDirectory(sourceDir)) {
      var srcFile:String = Path.join([sourceDir, entry]);
      var dstFile:String = Path.join([targetDir, entry]);

      if (sys.FileSystem.isDirectory(srcFile)) numCopied += copy(srcFile, dstFile);
      else {
        sys.io.File.copy(srcFile, dstFile);
        numCopied++;
      }
    }
    return numCopied;
  }

  public static function copyProjectAssets() {
    var cwd:String = Sys.getCwd();
    var assetSrcFolder = Path.join([cwd, "assets"]);
    var assetsDstFolder = Path.join([cwd, "bin"]);

    // make sure the assets folder exists
    if (!sys.FileSystem.exists(assetsDstFolder)) sys.FileSystem.createDirectory(assetsDstFolder);

    // copy it!
    var numCopied = copy(assetSrcFolder, assetsDstFolder);
    Sys.println('Copied ${numCopied} project assets to ${assetsDstFolder}!');
  }
  #end
}
