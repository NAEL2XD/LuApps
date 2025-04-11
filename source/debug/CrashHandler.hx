package debug;

// an fully working crash handler on ALL platforms
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import haxe.CallStack;
import haxe.io.Path;
import openfl.Lib;
import openfl.errors.Error;
import openfl.events.ErrorEvent;
import openfl.events.UncaughtErrorEvent;
import state.DummyState.Dummy;
import sys.FileSystem;
import sys.io.File;

using StringTools;

/**
 * Crash Handler.
 * @author YoshiCrafter29, Ne_Eo. MAJigsaw77 and mcagabe19
 */
class CrashHandler
{
	public static var errorMessage:String = "";

	public static function init():Void
	{
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError);
		untyped __global__.__hxcpp_set_critical_error_handler(onError);
	}

	private static function onUncaughtError(e:UncaughtErrorEvent):Void
	{
		try
		{
			e.preventDefault();
			e.stopPropagation();
			e.stopImmediatePropagation();

			var m:String = e.error;
			if (Std.isOfType(e.error, Error))
			{
				var err = cast(e.error, Error);
				m = '${err.message}';
			}
			else if (Std.isOfType(e.error, ErrorEvent))
			{
				var err = cast(e.error, ErrorEvent);
				m = '${err.text}';
			}
			final stack = CallStack.exceptionStack();
			final stackLabelArr:Array<String> = [];
			var stackLabel:String = "";
			// legacy code below for the messages
			var path:String;
			var dateNow:String = Date.now().toString();
			dateNow = dateNow.replace(" ", "_");
			dateNow = dateNow.replace(":", "'");

			path = "crash/" + "LuApps_" + dateNow + ".log";

			for (stackItem in stack)
			{
				switch (stackItem)
				{
					case CFunction:
						stackLabelArr.push("Non-Haxe (C) Function");
					case Module(c):
						stackLabelArr.push('Module ${c}');
					case FilePos(parent, file, line, col):
						switch (parent)
						{
							case Method(cla, func): stackLabelArr.push('${file.replace('.hx', '')}.$func() [line $line]');
							case _: stackLabelArr.push('${file.replace('.hx', '')} [line $line]');
						}
					case LocalFunction(v):
						stackLabelArr.push('Local Function ${v}');
					case Method(cl, m):
						stackLabelArr.push('${cl} - ${m}');
				}
			}
			stackLabel = stackLabelArr.join('\r\n');

			errorMessage += 'Uncaught Error: $m\n$stackLabel';
			trace(errorMessage);

			try
			{
				if (!FileSystem.exists("crash/"))
					FileSystem.createDirectory("crash/");
				File.saveContent(path, errorMessage + "\n");
			}
			catch (e)
				trace('Couldn\'t save error message. (${e.message})');

			Sys.println(errorMessage);
			Sys.println("Crash dump saved in " + Path.normalize(path));
		}
		catch (e:Dynamic)
			trace(e);

		FlxG.switchState(Crashie.new);
	}

	private static function onError(message:Dynamic):Void
		throw Std.string(message);
}

class Crashie extends FlxState
{
	override public function create()
	{
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();
		Main.changeWindowName("Crash!");

		var ohNo:FlxText = new FlxText(0, 0, 1280, 'LuApps ${Main.luversion} has crashed!');
		ohNo.setFormat('assets/fonts/main.ttf', 48, FlxColor.WHITE, FlxTextAlign.CENTER);
		ohNo.alpha = 0;
		ohNo.screenCenter();
		ohNo.y = 14;
		add(ohNo);

		var ohNo2:FlxText = new FlxText(0, 0, 1280, Main.sentenceCrash[FlxG.random.int(0, Main.sentenceCrash.length - 1)]);
		ohNo2.setFormat('assets/fonts/main.ttf', 18, FlxColor.WHITE, FlxTextAlign.CENTER);
		ohNo2.alpha = 0;
		ohNo2.screenCenter();
		ohNo2.y = 64;
		add(ohNo2);

		CrashHandler.errorMessage += "\n\nIf that happens because of an LuApp error,\neither give details on what you did or\nContact the developer that made the LuApp application";
		var stripClub:Array<String> = CrashHandler.errorMessage.split("\n");
		var i:Int = -1;
		var crash:Array<FlxText> = [];

		for (line in stripClub)
		{
			i++;
			crash.push(new FlxText(180, 0, 1280, line));
			crash[i].setFormat('assets/fonts/settings.ttf', 16, FlxColor.WHITE, FlxTextAlign.LEFT);
			crash[i].alpha = 0;
			crash[i].screenCenter();
			crash[i].x = 70;
			crash[i].y = 120 + (16 * i);
			add(crash[i]);
		}

		var tip:FlxText = new FlxText(180, 0, 1280, "Press any key to restart. (Press ENTER to launch GitHub)");
		tip.setFormat('assets/fonts/main.ttf', 36, FlxColor.WHITE, FlxTextAlign.CENTER);
		tip.alpha = 0;
		tip.screenCenter();
		tip.y = 655;
		add(tip);

		FlxTween.tween(ohNo, {alpha: 1}, 0.5);
		FlxTween.tween(ohNo2, {alpha: 1}, 0.5);
		FlxTween.tween(tip, {alpha: 1}, 0.5);
		for (spr in crash)
			FlxTween.tween(spr, {alpha: 1}, 0.5);

		super.create();
	}

	override public function update(elapsed:Float)
		if (FlxG.keys.justPressed.ANY)
		{
			if (FlxG.keys.justPressed.ENTER)
				FlxG.openURL("https://github.com/NAEL2XD/LuApps/issues");
			CrashHandler.errorMessage = "";
			Dummy.exit();
		}
}
