package;


import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.FlxG;
import haxe.Timer;
import PlayState;
import LuaEngine;
import debug.FPSCounter;

class Dummy extends FlxState
{
	public static var instance:Dummy;

	public var sprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var texts:Map<String, FlxText> = new Map<String, FlxText>();
	public var variables:Map<String, Dynamic> = new Map();
	public var tweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var timers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var luaArray:Array<LuaEngine> = PlayState.lolArray;

	var oldTime:Float = Timer.stamp(); //time

	override public function create()
	{
		instance = this;

		callOnLuas("create");
		super.create();
	}

	override public function update(elapsed:Float)
	{
		set('fullscreen',   FlxG.fullscreen);
		set('height',       FlxG.height);
		set('mouseMoved',   FlxG.mouse.justMoved);
		set('width',        FlxG.width);
		set('mouseX',       FlxG.mouse.x);
		set('mouseY',       FlxG.mouse.y);

		set('fps',          FPSCounter.currentFPS);
		set('time',         Timer.stamp() - oldTime);

		callOnLuas("update", [elapsed]);

		if (FlxG.keys.justPressed.ESCAPE)
			FlxG.resetGame();

		// Developer Mode
		if (FlxG.keys.justPressed.R) {
			sprites = [];
			texts = [];
			variables = [];
			tweens = [];
			luaArray = [];

			PlayState.lolArray = [];
			PlayState.lolArray.push(new LuaEngine(PlayState.modRaw + "main.lua"));
			FlxG.switchState(Dummy.new);
		}
		
		super.update(elapsed);
	}

	public function callOnLuas(event:String, args:Array<Dynamic> = null, ignoreStops = true, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal = LuaEngine.Function_Continue;
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [];

		for (script in luaArray) {
			if(exclusions.contains(script.scriptName))
				continue;

			final myValue = script.call(event, args);
			if(myValue == LuaEngine.Function_StopLua && !ignoreStops)
				break;
			
			if(myValue != null && myValue != LuaEngine.Function_Continue)
				returnVal = myValue;
		}
		return returnVal;
	}

	public function set(variable:String, arg:Dynamic) {
		for (i in 0...luaArray.length)
			luaArray[i].set(variable, arg);
	}

	public function getLuaObject(tag:String, text:Bool=true):FlxSprite {
		if (sprites.exists(tag)) return sprites.get(tag);
		if (text && texts.exists(tag)) return texts.get(tag);
		if (variables.exists(tag)) return variables.get(tag);
		return null;
	}
}