package;

import lime.app.Application;
import flixel.FlxGame;
import openfl.display.Sprite;
import debug.FPSCounter;
import CrashHandler;
import Prefs;

class Main extends Sprite
{
	// Main Settings
	public static var luversion:String = "0.0.1";

	public static var fpsVar:FPSCounter;

	public function new()
	{
		super();
		CrashHandler.init();

		addChild(new FlxGame(0, 0, PlayState));

		fpsVar = new FPSCounter(3, 3, 0x00FFFFFF);
		addChild(fpsVar);

		if (fpsVar != null) fpsVar.visible = true;

		Prefs.loadPrefs();
	}

	public static function changeWindowName(name:String = "")
		Application.current.window.title = 'Luapps v$luversion ${name != "" ? '- $name' : ''}';
}
