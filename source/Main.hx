package;

import lime.app.Application;
import flixel.FlxGame;
import openfl.display.Sprite;
import debug.FPSCounter;
import debug.CrashHandler;
import utils.Prefs;

class Main extends Sprite {
	// Main Settings
	public static var luversion:String = "DEV 0.0.1"; // fart version
	public static var sentenceCrash:Array<String> = [
		"Report to github!",
		"Hey world, i smashed his thingie ma bob!",
		"Hope you at least tried to fix it."
	];

	public static var fpsVar:FPSCounter;

	public function new() {
		super();
		CrashHandler.init();

		addChild(new FlxGame(0, 0, state.PlayState));

		fpsVar = new FPSCounter(3, 3, 0x00FFFFFF);
		addChild(fpsVar);
		fpsVar.visible = false;

		Prefs.loadPrefs();
	}

	public static function changeWindowName(name:String = "") Application.current.window.title = 'LuApps v$luversion ${name != "" ? '- $name' : ''}';
}