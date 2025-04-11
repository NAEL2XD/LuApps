package;

import debug.CrashHandler;
import debug.FPSCounter;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import lime.app.Application;
import openfl.display.Sprite;
import utils.Prefs;

#if desktop
import backend.ALSoftConfig; // Just to make sure DCE doesn't remove this, since it's not directly referenced anywhere else.
#end
class Main extends Sprite
{
	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var initialState:Class<FlxState> = state.StartupState; // default state it starts up in
	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	var framerate:Int = 60; // How many frames per second the game should run at.
	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets

	// Main Settings
	public static var luversion:String = "0.0.2"; // fart version
	public static var sentenceCrash:Array<String> = [
		"Report to github!",
		"Hey world, i smashed his thingie ma bob!",
		"Hope you at least tried to fix it.",
		"Some stuff are inspired from other engines, or even DevKitPro",
		"null",
		"Engine used Crash, It's very effective!",
		"oops",
		"No way dude! You Really Crashed The Game!? How Dare You!"
	];

	public static var fpsVar:FPSCounter;

	public function new()
	{
		super();
		CrashHandler.init();

		addChild(new FlxGame(gameWidth, gameHeight, initialState, #if (flixel < "5.0.0") zoom, #end framerate, framerate, skipSplash, startFullscreen));

		fpsVar = new FPSCounter(3, 698, 0x00FFFFFF);
		addChild(fpsVar);

		FlxG.mouse.useSystemCursor = true;

		Prefs.loadPrefs();
	}

	public static function changeWindowName(name:String = "")
		Application.current.window.title = 'LuApps v$luversion ${name != "" ? '- $name' : ''}';
}
