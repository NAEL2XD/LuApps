package state;


import flixel.sound.FlxSound;
import flixel.util.FlxColor;
import flixel.FlxSubState;
import utils.Prefs;
import lime.app.Application;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.FlxG;
import haxe.Timer;
import state.PlayState;
import engine.LuaEngine;
import debug.FPSCounter;

class Dummy extends FlxState
{
	public static var instance:Dummy;

	public var sprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var texts:Map<String, FlxText> = new Map<String, FlxText>();
	public var variables:Map<String, Dynamic> = new Map();
	public var tweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var timers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public static var luaArray:Array<LuaEngine> = [];
	public static var debugger:Array<FlxText> = [];

	public static var oldTime:Float = 0; //time

	override public function create() {
		instance = this;
		oldTime = Timer.stamp();

		updateVars();
		callOnLuas("create");
		super.create();
	}

	override public function update(elapsed:Float) {
		updateVars();

		for (text in debugger) add(text);

		callOnLuas("update", [elapsed]);

		if (FlxG.keys.justPressed.ESCAPE) openSubState(new Pause());

		if (FlxG.keys.justPressed.R && Prefs.debugger) {
			sprites = [];
			texts = [];
			variables = [];
			tweens = [];
			luaArray = [];
			debugger = [];

			luaArray.push(new LuaEngine(PlayState.modRaw + "source/main.lua"));
			FlxG.switchState(Dummy.new);
		}
		
		super.update(elapsed);
	}

	public static function exit() {
		try {
			Dummy.instance.sprites.clear();
			Dummy.instance.texts.clear();
			Dummy.instance.variables.clear();
			Dummy.instance.tweens.clear();
			Dummy.instance.timers.clear();
			Dummy.luaArray = [];
		} catch(e:Dynamic) {} // Failed to do those, prevent a crash.

		FlxG.resetGame();
	}

	public static function debugPrint(text:String, warn:Bool = false) {
		if (!Prefs.debugger) return;

		var l:Int = debugger.length;

		if (l == 37) {
			debugger[0].destroy();
			debugger.remove(debugger[0]);

			var i:Int = 0;
			for (text in debugger) {
				text.y = 20 * i;
				i++;
			}

			l--;
		}

		debugger.push(new FlxText(0, 20 * l, 1280, (warn ? "[WARN] " : "") + text, 20));
		debugger[l].setFormat('assets/fonts/debug.ttf', 20, warn ? FlxColor.YELLOW : FlxColor.WHITE);
	}

	public function updateVars() {
		set('author',       PlayState.author);
		set('fps',          FPSCounter.currentFPS);
		set('fullscreen',   FlxG.fullscreen);
		set('height',       Application.current.window.height);
		set('lowDetail',    Prefs.lowDetail);
		set('memory',       FPSCounter.curMemory);
		set('mempeak',      FPSCounter.curMaxMemory);
		set('modName',      PlayState.modName);
		set('modRaw',       PlayState.modRaw);
		set('mouseMoved',   FlxG.mouse.justMoved);
		set('mouseX',       FlxG.mouse.x);
		set('mouseY',       FlxG.mouse.y);
		set('time',         Timer.stamp() - oldTime);
		set('version',      Main.luversion);
		set('width',        Application.current.window.width);
	}

	public function callOnLuas(event:String, args:Array<Dynamic> = null, ignoreStops = true, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal = LuaEngine.Function_Continue;
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [];

		for (script in luaArray) {
			if(exclusions.contains(script.scriptName)) continue;

			final myValue = script.call(event, args);
			if(myValue == LuaEngine.Function_StopLua && !ignoreStops) break;
			if(myValue != null && myValue != LuaEngine.Function_Continue) returnVal = myValue;
		}
		return returnVal;
	}

	public function set(variable:String, arg:Dynamic) for (i in 0...luaArray.length) luaArray[i].set(variable, arg);

	public function getLuaObject(tag:String, text:Bool=true):FlxSprite {
		if (sprites.exists(tag)) return sprites.get(tag);
		if (text && texts.exists(tag)) return texts.get(tag);
		if (variables.exists(tag)) return variables.get(tag);
		return null;
	}
}

class Pause extends FlxSubState {
	public function new() super(0x00000000);

	var isMouseHidden:Bool = FlxG.mouse.enabled;

	private var pauseText:FlxText = new FlxText(0, 0, 1280, "Pause.", 24);
	private var buttonSpr:Array<FlxSprite> = [];
	private var buttonTxt:Array<FlxText> = [];

	private var music:FlxSound = new FlxSound();
	private var blackBG:FlxSprite = new FlxSprite();

	var isGoing:Bool = true;

	override public function create() {
		super.create();

		blackBG.makeGraphic(1920, 1080, FlxColor.BLACK);
		blackBG.alpha = 0;
		FlxTween.tween(blackBG, {alpha: 0.6}, 0.5);
		add(blackBG);

		if (FlxG.sound.music != null) FlxG.sound.music.pause();

		FlxG.mouse.enabled = true;
		FlxG.mouse.visible = true;

		pauseText.setFormat('assets/fonts/main.ttf', 96, FlxColor.WHITE, FlxTextAlign.CENTER);
		pauseText.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.GRAY, 4, 4);
		pauseText.screenCenter();
		pauseText.y = 26;
		pauseText.alpha = 0;
		FlxTween.tween(pauseText, {alpha: 1}, 0.5, {onComplete: e -> {
			isGoing = false;
		}});
		add(pauseText);

		var stuffies:Array<String> = ["Exit App", "Continue"];
		for (stuff in stuffies) {
			var i:Int = buttonSpr.length;
			buttonSpr.push(new FlxSprite().makeGraphic(260, 80, FlxColor.RED));
			buttonSpr[i].screenCenter();
			buttonSpr[i].x += (-(stuffies.length*200) + (i * 400)) + 200;
			buttonSpr[i].y = 550;
			buttonSpr[i].alpha = 0;
			FlxTween.tween(buttonSpr[i], {alpha: 1}, 0.5);
			add(buttonSpr[i]);

			buttonTxt.push(new FlxText(0, 0, 1280, stuff, 48));
			buttonTxt[i].setFormat('assets/fonts/main.ttf', 48, FlxColor.WHITE, FlxTextAlign.CENTER);
			buttonTxt[i].screenCenter();
			buttonTxt[i].x += (-(stuffies.length*200) + (i * 400)) + 200;
			buttonTxt[i].y = 555;
			buttonTxt[i].alpha = 0;
			FlxTween.tween(buttonTxt[i], {alpha: 1}, 0.5);
			add(buttonTxt[i]);
		}

		var modN:FlxText = new FlxText(0, 0, 1280, PlayState.modName, 36);
		modN.setFormat('assets/fonts/main.ttf', 36);
		modN.alignment = FlxTextAlign.RIGHT;
		modN.bold = true;
		modN.alpha = 0;
		modN.x = -15;
		modN.y = -20;
		new FlxTimer().start(0.35, e -> {
			FlxTween.tween(modN, {y: 10, alpha: 1}, 0.25);
		});
		add(modN);

		var modA:FlxText = new FlxText(0, 0, 1280, PlayState.author, 36);
		modA.setFormat('assets/fonts/main.ttf', 36);
		modA.alignment = FlxTextAlign.RIGHT;
		modA.bold = true;
		modA.alpha = 0;
		modA.x = -15;
		modA.y = 20;
		new FlxTimer().start(0.55, e -> {
			FlxTween.tween(modA, {y: 50, alpha: 1}, 0.25);
		});
		add(modA);

		music.loadEmbedded('assets/music/settings.ogg');
		music.fadeIn(8);
		music.looped = true;
		music.play();
	}

	override public function update(elapsed:Float) {
		var i:Int = 0;
		if (!isGoing) {
			for (sprite in buttonSpr) {
				if (FlxG.mouse.overlaps(sprite) && FlxG.mouse.justPressed) {
					isGoing = true;
					music.fadeOut(0.5);
	
					switch(buttonTxt[i].text) {
						case "Continue":
							music.stop();
							FlxG.mouse.enabled = isMouseHidden;
							FlxG.mouse.visible = isMouseHidden;

							for (sprite in members)
								FlxTween.tween(sprite, {alpha: 0}, 0.5, {onComplete: e -> {
									close();
								}});
	
						case "Exit App":
							for (sprite in members) FlxTween.tween(sprite, {alpha: 0}, 0.5);

							FlxTween.tween(blackBG, {alpha: 1}, 0.5, {onComplete: e -> {
								Dummy.exit();
							}});
					}
				}
	
				i++;
			}
		}
	}
}