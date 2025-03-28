package engine;

// Will credit them later..

import utils.Utils;
import haxe.Timer;
import lime.app.Application;
import flixel.util.FlxTimer;
import flixel.math.FlxVelocity;
import openfl.media.Sound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import openfl.display.BlendMode;
import openfl.display.BitmapData;
import sys.io.File;
import sys.FileSystem;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import llua.Lua;
import llua.LuaL;
import llua.State;
import llua.Convert;
import flixel.FlxG;
import flixel.FlxSprite;
import openfl.filters.ShaderFilter;
import state.DummyState;
import state.PlayState;
import utils.Prefs;
import lime.ui.FileDialog;

import hscript.Parser;
import hscript.Interp;
import hscript.Expr;

using StringTools;

class LuaEngine {
	public static var Function_Stop:Dynamic = "FUNCTIONSTOP";
	public static var Function_Continue:Dynamic = "FUNCTIONCONTINUE";
	public static var Function_StopLua:Dynamic = "FUNCTIONSTOPLUA";
	private static var storedFilters:Map<String, ShaderFilter> = []; // for a few shader functions

	public var lua:State = null;
	public var scriptName:String = '';
	public var closed:Bool = false;
	public static var hscript:HScript = null;
	
	public function new(script:String, ?scriptCode:String) {
		lua = LuaL.newstate();
		LuaL.openlibs(lua);
		Lua.init_callbacks(lua);

		try {
			var result:Int = scriptCode != null ? LuaL.dostring(lua, scriptCode) : LuaL.dofile(lua, script);
			var resultStr:String = Lua.tostring(lua, result);
			if(resultStr != null && result != 0) {
				trace('Error on lua script! ' + resultStr);
				lime.app.Application.current.window.alert(resultStr, 'Error on lua script!');
				Lua.close(lua);
				lua = null;
				FlxG.resetGame();
			}
		} catch(e:Dynamic) {
			trace(e);
			return;
		}
		scriptName = script;

		var raw:String = PlayState.modRaw;

		Lua_helper.add_callback(lua, "print", function(text:String) {
			Dummy.debugPrint(text);
		});

		Lua_helper.add_callback(lua, "makeSprite", function(tag:String, ?image:String, ?x:Float = 0, ?y:Float = 0) {
			function resetSpriteTag(tag:String) {
				if(!Dummy.instance.sprites.exists(tag))
					return;
		
				var thing:ModchartSprite = Dummy.instance.sprites.get(tag);
				thing.kill();
				if(thing.wasAdded)
					Dummy.instance.remove(thing, true);
		
				thing.destroy();
				Dummy.instance.sprites.remove(tag);
			}

			tag = tag.replace('.', '');
			resetSpriteTag(tag);
			var sprite:ModchartSprite = new ModchartSprite(x, y);
			if(image != null && image.length > 0) {
				var path:String = '${raw}assets/images/$image.png';
				var xd:BitmapData = null;
				if (FileSystem.exists(path))
					xd = BitmapData.fromFile(path);
				sprite.loadGraphic(xd);
			}
			sprite.antialiasing = Prefs.antiAliasing;
			Dummy.instance.sprites.set(tag, sprite);
			sprite.active = true;
		});

		Lua_helper.add_callback(lua, "addSprite", function(tag:String, ?front:Bool = false) {
			if(Dummy.instance.sprites.exists(tag)) {
				var thing:ModchartSprite = Dummy.instance.sprites.get(tag);
				if(!thing.wasAdded) {
					if(front)
						Dummy.instance.add(thing);
					else
					{
						var position:Int = 1;
						Dummy.instance.insert(position, thing);
					}
				}
			}
		});

		Lua_helper.add_callback(lua, "removeSprite", function(tag:String) {
			if(!Dummy.instance.sprites.exists(tag))
				return;

			var lol:ModchartSprite = Dummy.instance.sprites.get(tag);
			lol.destroy();
			Dummy.instance.sprites.remove(tag);
			lol.wasAdded = false;
		});

		Lua_helper.add_callback(lua, "makeText", function(tag:String, text:String, width:Int, x:Float, y:Float) {
			function resetTextTag(tag:String) {
				if(!Dummy.instance.texts.exists(tag))
					return;
		
				var thing:FlxText = Dummy.instance.texts.get(tag);
				if(thing != null)
					Dummy.instance.remove(thing, true);
		
				thing.destroy();
				Dummy.instance.texts.remove(tag);
			}

			tag = tag.replace('.', '');
			resetTextTag(tag);
			var leText:FlxText = new FlxText(x, y, width, text, 16);
			leText.setFormat("assets/fonts/main.ttf", 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			leText.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 4);
			Dummy.instance.texts.set(tag, leText);
		});

		Lua_helper.add_callback(lua, "addText", function(tag:String) {
			if(Dummy.instance.texts.exists(tag)) {
				var thing:FlxText = Dummy.instance.texts.get(tag);
				if (thing != null)  Dummy.instance.add(thing);
			}
		});

		Lua_helper.add_callback(lua, "removeText", function(tag:String) {
			if(!Dummy.instance.texts.exists(tag))
				return;

			var thing:FlxText = Dummy.instance.texts.get(tag);

			if(thing != null) {
				thing.destroy();
				Dummy.instance.texts.remove(tag);
				return;
			}

			Dummy.debugPrint('removeText: Object $thing does not exist!', true);
		});

		Lua_helper.add_callback(lua, "setTextString", function(tag:String, text:String) {
			var obj:FlxText = getTextObject(tag);
			if(obj != null)
			{
				obj.text = text;
				return true;
			}
			Dummy.debugPrint('setTextString: Object $tag doesn\'t exist!', true);
			return false;
		});

		Lua_helper.add_callback(lua, "setTextSize", function(tag:String, size:Int) {
			var obj:FlxText = getTextObject(tag);
			if(obj != null)
			{
				obj.size = size;
				return true;
			}
			Dummy.debugPrint('setTextSize: Object $tag doesn\'t exist!', true);
			return false;
		});

		Lua_helper.add_callback(lua, "setTextBorder", function(tag:String, size:Int, color:String) {
			var obj:FlxText = getTextObject(tag);
			if(obj != null)
			{
				var colorNum:Int = Std.parseInt(color);
				if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);

				obj.borderSize = size;
				obj.borderColor = colorNum;
				return true;
			}
			Dummy.debugPrint('setTextBorder: Object $tag doesn\'t exist!', true);
			return false;
		});

		Lua_helper.add_callback(lua, "setTextBorderStyle", function(tag:String, style:String, hexColor:String, ?size:Float = 1, ?quality:Float = 1) {
			function getStyle(type:String) {
				return switch(type.toLowerCase()) {
					case "shadow": FlxTextBorderStyle.SHADOW;
					case "outline": FlxTextBorderStyle.OUTLINE;
					case "outlinefast": FlxTextBorderStyle.OUTLINE_FAST;
					default: FlxTextBorderStyle.NONE;
				}
			}

			if (!Dummy.instance.texts.exists(tag)) {
				Dummy.debugPrint("setTextBorderStyle: Sprite does not exist.", true);
				return;
			}

			if (!hexColor.contains("0xFF")) hexColor = '0xFF$hexColor';

			var text:FlxText = Dummy.instance.texts.get(tag);
			text.setBorderStyle(getStyle(style), Std.parseInt(hexColor), size, quality);
		});

		Lua_helper.add_callback(lua, "setTextColor", function(tag:String, color:String) {
			var obj:FlxText = getTextObject(tag);
			if(obj != null)
			{
				var colorNum:Int = Std.parseInt(color);
				if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);

				obj.color = colorNum;
				return true;
			}
			Dummy.debugPrint('setTextColor: Object $tag doesn\'t exist!', true);
			return false;
		});

		Lua_helper.add_callback(lua, "setTextFont", function(tag:String, newFont:String) {
			var obj:FlxText = getTextObject(tag);
			if(obj != null)
			{
				obj.font = '${raw}assets/fonts/$newFont.ttf';
				return true;
			}
			Dummy.debugPrint('setTextFont: Object $tag doesn\'t exist!', true);
			return false;
		});

		Lua_helper.add_callback(lua, "setTextAlignment", function(tag:String, alignment:String = 'left') {
			var obj:FlxText = getTextObject(tag);
			if(obj != null)
			{
				obj.alignment = LEFT;
				switch(alignment.trim().toLowerCase())
				{
					case 'right':  obj.alignment = RIGHT;
					case 'center': obj.alignment = CENTER;
				}
				return true;
			}
			Dummy.debugPrint('setTextAlignment: Object $tag doesn\'t exist!', true);
			return false;
		});

		Lua_helper.add_callback(lua, "playMusic", function(music:String, ?volume:Float = 1, ?loop:Bool = false) {
			FlxG.sound.playMusic('${raw}assets/music/$music.ogg', volume, loop);
		});

		Lua_helper.add_callback(lua, "setWindowSize", function(?width:Int = 1280, ?height:Int = 720) {
			FlxG.resizeGame(width, height);
			FlxG.resizeWindow(width, height);
		});

		Lua_helper.add_callback(lua, "setProperty", function(variable:String, value:Dynamic) {
			var thing:Array<String> = variable.split('.');
			if(thing.length > 1) {
				setVarInArray(gpltw(thing), thing[thing.length-1], value);
				return;
			}

			Dummy.debugPrint("setProperty: Cannot access DUMMY variables!", true);
		});

		Lua_helper.add_callback(lua, "getProperty", function(variable:String) {
			var result:Dynamic = null;
			var thing:Array<String> = variable.split('.');
			if(thing.length > 1)
				result = getVarInArray(gpltw(thing), thing[thing.length-1]);
			else 
				Dummy.debugPrint("Cannot access DUMMY variables!", true);
			return result;
		});

		Lua_helper.add_callback(lua, "keyJustPressed", function(?key:String) {
			if (key == null)
				return FlxG.keys.justPressed.ANY;

			return Reflect.getProperty(FlxG.keys.justPressed, key);
		});

		Lua_helper.add_callback(lua, "keyPressed", function(?key:String) {
			if (key == null)
				return FlxG.keys.pressed.ANY;

			return Reflect.getProperty(FlxG.keys.pressed, key);
		});

		Lua_helper.add_callback(lua, "mouseClicked", function(?key:String) {
			var clicked:Bool = FlxG.mouse.justPressed;
			if (key != null) {
				key = key.toLowerCase();

				switch (key) {
					case "middle": clicked = FlxG.mouse.justPressedMiddle;
					case "right":  clicked = FlxG.mouse.justPressedRight;
					case "any": clicked = (FlxG.mouse.justPressed ||FlxG.mouse.justPressedMiddle || FlxG.mouse.justPressedRight);
				}
			}

			return clicked;
		});

		Lua_helper.add_callback(lua, "mousePressed", function(?key:String) {
			var pressed:Bool = FlxG.mouse.pressed;
			if (key != null) {
				key = key.toLowerCase();

				switch (key) {
					case "middle": pressed = FlxG.mouse.pressedMiddle;
					case "right":  pressed = FlxG.mouse.pressedRight;
					case "any": pressed = (FlxG.mouse.pressed ||FlxG.mouse.pressedMiddle || FlxG.mouse.pressedRight);
				}
			}

			return pressed;
		});

		Lua_helper.add_callback(lua, "setBlend", function(obj:String, blend:String = '') {
			function blendModeFromString(blend:String):BlendMode {
				switch(blend.toLowerCase().trim()) {
					case 'add': return ADD;
					case 'alpha': return ALPHA;
					case 'darken': return DARKEN;
					case 'difference': return DIFFERENCE;
					case 'erase': return ERASE;
					case 'hardlight': return HARDLIGHT;
					case 'invert': return INVERT;
					case 'layer': return LAYER;
					case 'lighten': return LIGHTEN;
					case 'multiply': return MULTIPLY;
					case 'overlay': return OVERLAY;
					case 'screen': return SCREEN;
					case 'shader': return SHADER;
					case 'subtract': return SUBTRACT;
				}
				return NORMAL;
			}

			var thinger = Dummy.instance.getLuaObject(obj);
			if(thinger!=null) {
				thinger.blend = blendModeFromString(blend);
				return true;
			}

			var thing:Array<String> = obj.split('.');
			var spr:FlxSprite = getObjectDirectly(thing[0]);
			if(thing.length > 1)
				spr = getVarInArray(gpltw(thing), thing[thing.length-1]);

			if(spr != null) {
				spr.blend = blendModeFromString(blend);
				return true;
			}
			Dummy.debugPrint('setBlend: Object $obj doesn\'t exist!', true);
			return false;
		});

		Lua_helper.add_callback(lua, "doTweenX", function(tag:String, vars:String, value:Dynamic, duration:Float, ?ease:String = 'linear') {
			var tween:Dynamic = tweenStuff(tag, vars);
			if(tween != null) {
				Dummy.instance.tweens.set(tag, FlxTween.tween(tween, {x: value}, duration, {ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						Dummy.instance.callOnLuas('tweenComplete', [tag]);
						Dummy.instance.tweens.remove(tag);
					}
				}));
			} else Dummy.debugPrint('doTweenX: Couldn\'t find object: $vars', true);
		});

		Lua_helper.add_callback(lua, "doTweenY", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			var tween:Dynamic = tweenStuff(tag, vars);
			if(tween != null) {
				Dummy.instance.tweens.set(tag, FlxTween.tween(tween, {y: value}, duration, {ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						Dummy.instance.callOnLuas('tweenComplete', [tag]);
						Dummy.instance.tweens.remove(tag);
					}
				}));
			} else Dummy.debugPrint('doTweenY: Couldn\'t find object: $vars', true);
		});

		Lua_helper.add_callback(lua, "doTweenAngle", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			var tween:Dynamic = tweenStuff(tag, vars);
			if(tween != null) {
				Dummy.instance.tweens.set(tag, FlxTween.tween(tween, {angle: value}, duration, {ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						Dummy.instance.callOnLuas('tweenComplete', [tag]);
						Dummy.instance.tweens.remove(tag);
					}
				}));
			} else Dummy.debugPrint('doTweenAngle: Couldn\'t find object: $vars', true);
		});

		Lua_helper.add_callback(lua, "doTweenAlpha", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			var tween:Dynamic = tweenStuff(tag, vars);
			if(tween != null) {
				Dummy.instance.tweens.set(tag, FlxTween.tween(tween, {alpha: value}, duration, {ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						Dummy.instance.callOnLuas('tweenComplete', [tag]);
						Dummy.instance.tweens.remove(tag);
					}
				}));
			} else Dummy.debugPrint('doTweenAlpha: Couldn\'t find object: $vars', true);
		});

		Lua_helper.add_callback(lua, "doTweenColor", function(tag:String, vars:String, targetColor:String, duration:Float, ease:String) {
			var tween:Dynamic = tweenStuff(tag, vars);
			if(tween != null) {
				var color:Int = Std.parseInt(targetColor);
				if(!targetColor.startsWith('0x')) color = Std.parseInt('0xff' + targetColor);

				var curColor:FlxColor = tween.color;
				curColor.alphaFloat = tween.alpha;
				Dummy.instance.tweens.set(tag, FlxTween.color(tween, duration, curColor, color, {ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						Dummy.instance.tweens.remove(tag);
						Dummy.instance.callOnLuas('tweenComplete', [tag]);
					}
				}));
			} else Dummy.debugPrint('doTweenColor: Couldn\'t find object: $vars', true);
		});

		Lua_helper.add_callback(lua, "setMouseVisibility", function(?show:Bool = true) {
			FlxG.mouse.enabled = show;
			FlxG.mouse.visible = show;
		});

		Lua_helper.add_callback(lua, "playSound", function(sound:String) {
			var n:String = '${raw}assets/sounds/$sound.ogg';

			if (!FileSystem.exists(n)) {
				Dummy.debugPrint('playSound: Couldn\'t find sound file: $n', true);
				return;
			}

			var sound:Sound = Sound.fromFile(n);
			sound.play();
		});

		Lua_helper.add_callback(lua, "moveTowardsMouse", function(tag:String, speed:Int = 60) {
			if (Dummy.instance.sprites.exists(tag) || Dummy.instance.texts.exists(tag)){
				FlxVelocity.moveTowardsMouse(Dummy.instance.getLuaObject(tag), speed);
				return;
			}

			Dummy.debugPrint("moveTowardsMouse: Sprite does not exist, did you make a typo?", true);
		});

		Lua_helper.add_callback(lua, "sendPopup", function(?title:String = "", desc:String = "") {
			if (title == "") title = PlayState.modName;

			if (desc == "") {
				Dummy.debugPrint("sendPopup: Argument 2: Desc cannot be empty!", true);
				return;
			}

			lime.app.Application.current.window.alert(desc, title);
		});

		Lua_helper.add_callback(lua, "randomInt", function(?min:Int = 1, ?max:Int = 10) {
			return FlxG.random.int(min, max);
		});

		Lua_helper.add_callback(lua, "randomFloat", function(?min:Float = 0, ?max:Float = 1) {
			return FlxG.random.float(min, max);
		});

		Lua_helper.add_callback(lua, "randomBool", function(?chance:Float = 50) {
			if (chance > 100) chance = 100;
			if (chance < 0)   chance = 0;

			return FlxG.random.bool(chance);
		});

		Lua_helper.add_callback(lua, "cleanMemory", function() {
			openfl.system.System.gc();
		});

		Lua_helper.add_callback(lua, "makeGraphic", function(obj:String, ?width:Int = 256, ?height:Int = 256, ?color:String = "FFFFFF") {
			var colorNum:Int = Std.parseInt(color);
			if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);

			var spr:FlxSprite = Dummy.instance.getLuaObject(obj,false);
			if(spr!=null) {
				Dummy.instance.getLuaObject(obj,false).makeGraphic(width, height, colorNum);
				return;
			}

			var object:FlxSprite = Reflect.getProperty(Dummy.instance, obj);
			if(object != null) object.makeGraphic(width, height, colorNum);
		});

		Lua_helper.add_callback(lua, "screenCenter", function(obj:String, ?pos:String = 'xy') {
			var spr:FlxSprite = Dummy.instance.getLuaObject(obj);

			if(spr == null) {
				var thing:Array<String> = obj.split('.');
				spr = getObjectDirectly(thing[0]);
				if(thing.length > 1) spr = getVarInArray(gpltw(thing), thing[thing.length-1]);
			}

			if(spr != null)
			{
				switch(pos.trim().toLowerCase())
				{
					case 'x': spr.screenCenter(X);
					case 'y': spr.screenCenter(Y);
					default:  spr.screenCenter(XY);
				}
				return;
			}

			Dummy.debugPrint('screenCenter: Object $obj doesn\'t exist!', true);
		});

		Lua_helper.add_callback(lua, "stringStartsWith", function(str:String, start:String) {
			return str.startsWith(start);
		});

		Lua_helper.add_callback(lua, "stringEndsWith", function(str:String, end:String) {
			return str.endsWith(end);
		});

		Lua_helper.add_callback(lua, "stringSplit", function(str:String, split:String) {
			return str.split(split);
		});

		Lua_helper.add_callback(lua, "stringTrim", function(str:String) {
			return str.trim();
		});

		Lua_helper.add_callback(lua, "scaleObject", function(obj:String, x:Float, y:Float) {
			if(Dummy.instance.getLuaObject(obj)!=null) {
				var Stuff:FlxSprite = Dummy.instance.getLuaObject(obj);
				Stuff.scale.set(x, y);
				Stuff.updateHitbox();
				return;
			}

			var thing3:Array<String> = obj.split('.');
			var thing2:FlxSprite = getObjectDirectly(thing3[0]);
			if(thing3.length > 1) thing2 = getVarInArray(gpltw(thing3), thing3[thing3.length-1]);

			if(thing2 != null) {
				thing2.scale.set(x, y);
				thing2.updateHitbox();
				return;
			}
			Dummy.debugPrint('scaleObject: Couldnt find object: $obj', true);
		});

		Lua_helper.add_callback(lua, "runTimer", function(tag:String, time:Float = 1, loops:Int = 1) {
			cancelTimer(tag);
			Dummy.instance.timers.set(tag, new FlxTimer().start(time, function(tmr:FlxTimer) {
				if(tmr.finished)
					Dummy.instance.timers.remove(tag);
				Dummy.instance.callOnLuas('timerComplete', [tag, tmr.loops, tmr.loopsLeft]);
			}, loops));
		});

		Lua_helper.add_callback(lua, "cancelTimer", function(tag:String) {
			cancelTimer(tag);
		});

		Lua_helper.add_callback(lua, "cancelTween", function(tag:String) {
			cancelTween(tag);
		});

		Lua_helper.add_callback(lua, "getContent", function(file:String = ''):String {
			var n:String = '${raw}assets/data/$file';
			if (file == '') {
				Dummy.debugPrint("getContent: File argument is empty!", true);
				return "";
			}

			if (!FileSystem.exists(n)) {
				Dummy.debugPrint('getContent: File does not exist on $n! Did you make a typo?', true);
				return "";
			}
				
			var plswork:Dynamic = File.getContent(n);
			return plswork;
		});

		Lua_helper.add_callback(lua, "getColorFromFlx", function(color:String = ''):FlxColor {
			return switch(color) {
				case 'BLACK':       FlxColor.BLACK;
				case 'BLUE':        FlxColor.BLUE;
				case 'BROWN':       FlxColor.BROWN;
				case 'CYAN':        FlxColor.CYAN;
				case 'GRAY':        FlxColor.GRAY;
				case 'GREEN':       FlxColor.GREEN;
				case 'LIME':        FlxColor.LIME;
				case 'MAGENTA':     FlxColor.MAGENTA;
				case 'ORANGE' :     FlxColor.ORANGE;
				case 'PINK':        FlxColor.PINK;
				case 'PURPLE':      FlxColor.PURPLE;
				case 'RED':         FlxColor.RED;
				case 'TRANSPARENT': FlxColor.TRANSPARENT;
				case 'WHITE':       FlxColor.WHITE;
				case 'YELLOW':      FlxColor.YELLOW;
				default:            FlxColor.WHITE;
			}
		});

		Lua_helper.add_callback(lua, "setWindowName", function(name:String) {
			Main.changeWindowName(name);
		});

		Lua_helper.add_callback(lua, "objectsOverlap", function(obj1:String, obj2:String) {
			var namesArray:Array<String> = [obj1, obj2];
			var objectsArray:Array<FlxSprite> = [];
			for (i in 0...namesArray.length) {
				var thinhg = Dummy.instance.getLuaObject(namesArray[i]);
				if(thinhg != null) objectsArray.push(thinhg); else objectsArray.push(Reflect.getProperty(Dummy.instance, namesArray[i]));
			}

			return !objectsArray.contains(null) && FlxG.overlap(objectsArray[0], objectsArray[1]);
		});

		Lua_helper.add_callback(lua, "runHaxeCode", function(codeToRun:String) {
			var retVal:Dynamic = null;

			initHaxeModule();
			try {
				retVal = hscript.execute(codeToRun);
			} catch (e:Dynamic) Dummy.debugPrint(scriptName + ":" + lastCalledFunction + " - " + e, true);

			if(retVal != null && !isOfTypes(retVal, [Bool, Int, Float, String, Array])) retVal = null;
			return retVal;
		});

		Lua_helper.add_callback(lua, "addHaxeLibrary", function(libName:String, ?libPackage:String = '') {
			initHaxeModule();
			try {
				var str:String = '';
				if(libPackage.length > 0) str = libPackage + '.';

				hscript.variables.set(libName, Type.resolveClass(str + libName));
			} catch (e:Dynamic) Dummy.debugPrint(scriptName + ":" + lastCalledFunction + " - " + e, true);
		});

		Lua_helper.add_callback(lua, "clearConsole", function() {
			for (text in Dummy.debugger) text.destroy();
			
			Dummy.debugger = [];
		});

		Lua_helper.add_callback(lua, "resetWindowSize", function() {
			Utils.setDefaultResolution();
		});

		Lua_helper.add_callback(lua, "exit", function() {
			Dummy.exit();
		});

		Lua_helper.add_callback(lua, "promptFile", function(title:String = "Choose a file.", filter:String = "*") {
			var file = new FileDialog();
			var n:Dynamic = "";
			file.onOpen.add(f -> {
				n = f;
			});
			file.open(filter, null, title);

			return n;
		});
	}

	public function set(variable:String, data:Dynamic) {
		if (lua == null) return;

		Convert.toLua(lua, data);
		Lua.setglobal(lua, variable);
	}

	inline static function getTextObject(name:String):FlxText
		return Dummy.instance.texts.exists(name) ? Dummy.instance.texts.get(name) : Reflect.getProperty(Dummy.instance, name);

	var lastCalledFunction:String = '';
	public function call(func:String, args:Array<Dynamic>):Dynamic {
		if(closed) return Function_Continue;

		try {
			if(lua == null) return Function_Continue;

			Lua.getglobal(lua, func);
			var type:Int = Lua.type(lua, -1);

			if (type != Lua.LUA_TFUNCTION) {
				if (type > Lua.LUA_TNIL) 
					Dummy.debugPrint('$func: attempt to call a ${typeToString(type)} value', true);

				Lua.pop(lua, 1);
				return Function_Continue;
			}

			for (arg in args) Convert.toLua(lua, arg);
			var status:Int = Lua.pcall(lua, args.length, 1, 0);
			// Checks if it's not successful, then show a error.
			if (status != Lua.LUA_OK) {
				var error:String = getErrorMessage(status);
				if (!FileSystem.exists("errors/"))
					FileSystem.createDirectory("errors/");
				if (!FileSystem.exists('errors/${PlayState.modName}/'))
					FileSystem.createDirectory('errors/${PlayState.modName}/');

				var dateNow:String = Date.now().toString();
				dateNow = dateNow.replace(" ", "_");
				dateNow = dateNow.replace(":", "'");

				var path:String = 'errors/${PlayState.modName}/main_$dateNow.log';

				File.saveContent(path, '$func:\n$error');

				Dummy.debugPrint('$func: $error | This warning is saved on $path', true);
				return Function_StopLua;
			}

			var result:Dynamic = cast Convert.fromLua(lua, -1);
			if (result == null) result = Function_Continue;

			Lua.pop(lua, 1);
			return result;
		}
		catch (e:Dynamic) {
			trace(e);
		}
		return Function_Continue;
	}

	function typeToString(type:Int):String {
		switch(type) {
			case Lua.LUA_TBOOLEAN: return "boolean";
			case Lua.LUA_TNUMBER: return "number";
			case Lua.LUA_TSTRING: return "string";
			case Lua.LUA_TTABLE: return "table";
			case Lua.LUA_TFUNCTION: return "function";
		}
		if (type <= Lua.LUA_TNIL) return "nil";
		return "unknown";
	}

	function tweenStuff(tag:String, vars:String) {
		cancelTween(tag);
		var variables:Array<String> = vars.split('.');
		var sexyProp:Dynamic = getObjectDirectly(variables[0]);
		if(variables.length > 1) {
			sexyProp = getVarInArray(gpltw(variables), variables[variables.length-1]);
		}
		return sexyProp;
	}

	function cancelTween(tag:String) {
		if(Dummy.instance.tweens.exists(tag)) {
			Dummy.instance.tweens.get(tag).cancel();
			Dummy.instance.tweens.get(tag).destroy();
			Dummy.instance.tweens.remove(tag);
		}
	}

	function cancelTimer(tag:String) {
		if(Dummy.instance.timers.exists(tag)) {
			var theTimer:FlxTimer = Dummy.instance.timers.get(tag);
			theTimer.cancel();
			theTimer.destroy();
			Dummy.instance.timers.remove(tag);
		}
	}

	function getFlxEaseByString(?ease:String = '') {
		switch(ease.toLowerCase().trim()) {
			case 'backin': return FlxEase.backIn;
			case 'backinout': return FlxEase.backInOut;
			case 'backout': return FlxEase.backOut;
			case 'bouncein': return FlxEase.bounceIn;
			case 'bounceinout': return FlxEase.bounceInOut;
			case 'bounceout': return FlxEase.bounceOut;
			case 'circin': return FlxEase.circIn;
			case 'circinout': return FlxEase.circInOut;
			case 'circout': return FlxEase.circOut;
			case 'cubein': return FlxEase.cubeIn;
			case 'cubeinout': return FlxEase.cubeInOut;
			case 'cubeout': return FlxEase.cubeOut;
			case 'elasticin': return FlxEase.elasticIn;
			case 'elasticinout': return FlxEase.elasticInOut;
			case 'elasticout': return FlxEase.elasticOut;
			case 'expoin': return FlxEase.expoIn;
			case 'expoinout': return FlxEase.expoInOut;
			case 'expoout': return FlxEase.expoOut;
			case 'quadin': return FlxEase.quadIn;
			case 'quadinout': return FlxEase.quadInOut;
			case 'quadout': return FlxEase.quadOut;
			case 'quartin': return FlxEase.quartIn;
			case 'quartinout': return FlxEase.quartInOut;
			case 'quartout': return FlxEase.quartOut;
			case 'quintin': return FlxEase.quintIn;
			case 'quintinout': return FlxEase.quintInOut;
			case 'quintout': return FlxEase.quintOut;
			case 'sinein': return FlxEase.sineIn;
			case 'sineinout': return FlxEase.sineInOut;
			case 'sineout': return FlxEase.sineOut;
			case 'smoothstepin': return FlxEase.smoothStepIn;
			case 'smoothstepinout': return FlxEase.smoothStepInOut;
			case 'smoothstepout': return FlxEase.smoothStepInOut;
			case 'smootherstepin': return FlxEase.smootherStepIn;
			case 'smootherstepinout': return FlxEase.smootherStepInOut;
			case 'smootherstepout': return FlxEase.smootherStepOut;
		}
		return FlxEase.linear;
	}

	function getErrorMessage(status:Int):String {
		var v:String = Lua.tostring(lua, -1);
		Lua.pop(lua, 1);

		if (v != null) v = v.trim();
		if (v == null || v == "") {
			switch(status) {
				case Lua.LUA_ERRRUN: return "Runtime Error";
				case Lua.LUA_ERRMEM: return "Memory Allocation Error";
				case Lua.LUA_ERRERR: return "Critical Error";
			}
			return "Unknown Error";
		}

		return v;
	}

	public static function gpltw(thing:Array<String>, ?checkForTextsToo:Bool = true, ?getProperty:Bool=true):Dynamic
	{
		var stuff:Dynamic = getObjectDirectly(thing[0], checkForTextsToo);
		var end = thing.length;
		if(getProperty)end=thing.length-1;

		for (i in 1...end)
			stuff = getVarInArray(stuff, thing[i]);
		return stuff;
	}

	public static function getObjectDirectly(objectName:String, ?checkForTextsToo:Bool = true):Dynamic
	{
		var thing:Dynamic = Dummy.instance.getLuaObject(objectName, checkForTextsToo);
		if (thing == null)
			thing = getVarInArray(Dummy.instance, objectName);

		return thing;
	}

	public static function getVarInArray(instance:Dynamic, variable:String):Any
	{
		var Stuff:Array<String> = variable.split('[');
		if(Stuff.length > 1)
		{
			var blah:Dynamic = null;
			if(Dummy.instance.variables.exists(Stuff[0]))
			{
				var retVal:Dynamic = Dummy.instance.variables.get(Stuff[0]);
				if(retVal != null)
					blah = retVal;
			}
			else
				blah = Reflect.getProperty(instance, Stuff[0]);

			for (i in 1...Stuff.length)
			{
				var leNum:Dynamic = Stuff[i].substr(0, Stuff[i].length - 1);
				blah = blah[leNum];
			}
			return blah;
		}

		if(Dummy.instance.variables.exists(variable))
		{
			var retVal:Dynamic = Dummy.instance.variables.get(variable);
			if(retVal != null)
				return retVal;
		}

		return Reflect.getProperty(instance, variable);
	}

	public static function setVarInArray(instance:Dynamic, variable:String, value:Dynamic):Any
	{
		var Stuff:Array<String> = variable.split('[');
		if(Stuff.length > 1)
		{
			var blah:Dynamic = null;
			if(Dummy.instance.variables.exists(Stuff[0]))
			{
				var retVal:Dynamic = Dummy.instance.variables.get(Stuff[0]);
				if(retVal != null)
					blah = retVal;
			}
			else
				blah = Reflect.getProperty(instance, Stuff[0]);

			for (i in 1...Stuff.length)
			{
				var leNum:Dynamic = Stuff[i].substr(0, Stuff[i].length - 1);
				if(i >= Stuff.length-1) //Last array
					blah[leNum] = value;
				else //Anything else
					blah = blah[leNum];
			}
			return blah;
		}
			
		if(Dummy.instance.variables.exists(variable))
		{
			Dummy.instance.variables.set(variable, value);
			return true;
		}

		Reflect.setProperty(instance, variable, value);
		return true;
	}

	public static function isOfTypes(value:Any, types:Array<Dynamic>)
		{
			for (type in types) if(Std.isOfType(value, type)) return true;
			return false;
		}

	public function initHaxeModule()
	{
		if(hscript == null)
		{
			trace('initializing haxe interp for: $scriptName');
			hscript = new HScript(); //TO DO: Fix issue with 2 scripts not being able to use the same variable names
		}
	}
}

class HScript
{
	public static var parser:Parser = new Parser();
	public var interp:Interp;

	public var variables(get, never):Map<String, Dynamic>;

	public function get_variables() return interp.variables;

	public function new()
	{
		interp = new Interp();
		interp.variables.set('FlxG', FlxG);
		interp.variables.set('FlxSprite', FlxSprite);
		interp.variables.set('FlxText', FlxText);
		interp.variables.set('FlxTimer', FlxTimer);
		interp.variables.set('FlxTween', FlxTween);
		interp.variables.set('FlxEase', FlxEase);
		interp.variables.set('PlayState', PlayState);
		interp.variables.set('game', Dummy.instance);
		interp.variables.set('Prefs', Prefs);
		interp.variables.set('ShaderFilter', ShaderFilter);
		interp.variables.set('StringTools', StringTools);

		interp.variables.set('setVar', function(name:String, value:Dynamic)
		{
			Dummy.instance.variables.set(name, value);
		});

		interp.variables.set('getVar', function(name:String)
		{
			var result:Dynamic = null;
			if(Dummy.instance.variables.exists(name)) result = Dummy.instance.variables.get(name);
			return result;
		});

		interp.variables.set('removeVar', function(name:String)
		{
			if(Dummy.instance.variables.exists(name))
			{
				Dummy.instance.variables.remove(name);
				return true;
			}
			return false;
		});
	}

	public function execute(codeToRun:String):Dynamic
	{
		@:privateAccess
		HScript.parser.line = 1;
		HScript.parser.allowTypes = true;
		return interp.execute(HScript.parser.parseString(codeToRun));
	}
}

class ModchartSprite extends FlxSprite
{
	public var wasAdded:Bool = false;
	public var animOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();
	//public var isInFront:Bool = false;

	public function new(?x:Float = 0, ?y:Float = 0)
	{
		super(x, y);
		antialiasing = true;
	}
}