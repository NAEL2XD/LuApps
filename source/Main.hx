package;

import debug.CrashHandler;
import debug.FPSCounter;
import flixel.FlxG;
import flixel.FlxGame;
import lime.app.Application;
import openfl.display.Sprite;
import state.StartupState;
import utils.Prefs;

class Main extends Sprite {
	public static var fpsVar:FPSCounter;
	
	// Main Settings
	public static var luversion:String = "0.0.2"; // version
	public static var sentenceCrash:Array<String> = [ // funny crash sentence
		"Report to github!",
		"Hey world, i smashed his thingie ma bob!",
		"Hope you at least tried to fix it.",
		"Some stuff are inspired from other engines, or even DevKitPro",
		"null",
		"Engine used Crash, It's very effective!",
		"oops",
		"No way dude! You Really Crashed The Game!? How Dare You!"
	];

	public function new() {
		super();
		CrashHandler.init();

		addChild(new FlxGame(0, 0, state.StartupState, 120, 120, true));

		fpsVar = new FPSCounter(3, 698, 0x00FFFFFF);
		addChild(fpsVar);

		FlxG.mouse.useSystemCursor = true;

		Prefs.loadPrefs();
	}

	public static function changeWindowName(name:String = "") Application.current.window.title = 'LuApps v$luversion ${name != "" ? '- $name' : ''}';
}