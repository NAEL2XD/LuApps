package;

import flixel.FlxG;
import lime.app.Application;
import flixel.FlxGame;
import openfl.display.Sprite;
import debug.FPSCounter;
import debug.CrashHandler;
import utils.Prefs;

class Main extends Sprite {
	// Main Settings
	public static var luversion:String = "0.0.1"; // fart version
	public static var sentenceCrash:Array<String> = [
		"Report to github!",
		"Hey world, i smashed his thingie ma bob!",
		"Hope you at least tried to fix it.",
		"Some stuff are inspired from other engines, or even DevKitPro"
	];

	public static var fpsVar:FPSCounter;

	public function new() {
		super();
		CrashHandler.init();

		addChild(new FlxGame(0, 0, state.PlayState, 120, 120, true));

		fpsVar = new FPSCounter(3, 698, 0x00FFFFFF);
		addChild(fpsVar);

		FlxG.mouse.useSystemCursor = true;

		Prefs.loadPrefs();
	}

	public static function changeWindowName(name:String = "") Application.current.window.title = 'LuApps v$luversion ${name != "" ? '- $name' : ''}';
}