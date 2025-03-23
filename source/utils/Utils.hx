package utils;

import flixel.FlxG;

class Utils {
	public static function setDefaultResolution() {
		var resV = cast(Prefs.screenSize, String);

    	if (resV != null) {
    		var parts = resV.split('x');
			var res:Array<Int> = [for (i in 0...2) Std.parseInt(parts[i])];

    		FlxG.resizeGame(res[0], res[1]);
			lime.app.Application.current.window.width = res[0];
			lime.app.Application.current.window.height = res[1];
    	}
	}
}