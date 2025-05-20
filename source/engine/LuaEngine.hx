package engine;

import state.DummyState.Pause;

class LuaEngine {
	public static var Function_Stop:Dynamic = "FUNCTIONSTOP";
	public static var Function_Continue:Dynamic = "FUNCTIONCONTINUE";
	public static var Function_StopLua:Dynamic = "FUNCTIONSTOPLUA";

	public var lua:State = null;
	public var scriptName:String = '';
	public var closed:Bool = false;
	
	var raw:String = "";
	public function new(script:String, ?scriptCode:String) {
		lua = LuaL.newstate();
		LuaL.openlibs(lua);
		Lua.init_callbacks(lua);

		raw = PlayState.modRaw;

		try {
			var result:Int = scriptCode != null ? LuaL.dostring(lua, scriptCode) : LuaL.dofile(lua, script);
			var resultStr:String = Lua.tostring(lua, result);
			if(resultStr != null && result != 0) {
				trace('Error on lua script! $resultStr');
				Application.current.window.alert(resultStr, 'Error on lua script!');
				Lua.close(lua);
				lua = null;
				FlxG.resetGame();
			}
		} catch(e:Dynamic) {
			trace(e);
			return;
		}
		scriptName = script;

		Lua_helper.add_callback(lua, "DEBUG_print", function(text:String) Dummy.debugPrint(text));
		Lua_helper.add_callback(lua, "SPRITE_make", function(tag:String, ?image:String, ?x:Float = 0, ?y:Float = 0) {
			function resetSpriteTag(tag:String) {
				if(!Dummy.instance.sprites.exists(tag)) return;
		
				var thing:ModchartSprite = Dummy.instance.sprites.get(tag);
				thing.kill();
				if(thing.wasAdded) Dummy.instance.remove(thing, true);

				thing.destroy();
				Dummy.instance.sprites.remove(tag);
			}

			tag = tag.replace('.', '');
			resetSpriteTag(tag);
			var sprite:ModchartSprite = new ModchartSprite(x, y);
			if(image != null && image.length > 0) {
				var path:String = '${raw}assets/images/$image.png';
				var xd:BitmapData = null;
				if (FileSystem.exists(path)) xd = BitmapData.fromFile(path);
				sprite.loadGraphic(xd);
			}
			sprite.antialiasing = Prefs.antiAliasing;
			Dummy.instance.sprites.set(tag, sprite);
			sprite.active = true;
		});

		Lua_helper.add_callback(lua, "SPRITE_render", function(tag:String, ?front:Bool = false) {
			if(Dummy.instance.sprites.exists(tag)) {
				var thing:ModchartSprite = Dummy.instance.sprites.get(tag);
				if(!thing.wasAdded) {
					if(front) Dummy.instance.add(thing);
					else Dummy.instance.insert(1, thing);
				}
			}
		});

		Lua_helper.add_callback(lua, "SPRITE_destroy", function(tag:String) {
			if(!Dummy.instance.sprites.exists(tag)) return;

			var lol:ModchartSprite = Dummy.instance.sprites.get(tag);
			lol.destroy();
			Dummy.instance.sprites.remove(tag);
			lol.wasAdded = false;
		});

		Lua_helper.add_callback(lua, "TEXT_make", function(tag:String, text:String, width:Int, x:Float, y:Float) {
			function resetTextTag(tag:String) {
				if(!Dummy.instance.texts.exists(tag)) return;
		
				var thing:FlxText = Dummy.instance.texts.get(tag);
				if(thing != null) Dummy.instance.remove(thing, true);
				thing.destroy();
				Dummy.instance.texts.remove(tag);
			}

			tag = tag.replace('.', '');
			resetTextTag(tag);
			var leText:FlxText = new UtilText(x, y, width, text, 16, CENTER);
			Dummy.instance.texts.set(tag, leText);
		});

		Lua_helper.add_callback(lua, "TEXT_render", function(tag:String) {
			if(Dummy.instance.texts.exists(tag)) {
				var thing:FlxText = Dummy.instance.texts.get(tag);
				if (thing != null)  Dummy.instance.add(thing);
			}
		});

		Lua_helper.add_callback(lua, "TEST_destroy", function(tag:String) {
			if(!Dummy.instance.texts.exists(tag)) return;

			var thing:FlxText = Dummy.instance.texts.get(tag);
			if(thing != null) {
				thing.destroy();
				Dummy.instance.texts.remove(tag);
				return;
			}

			Dummy.debugPrint('TEST_destroy: Object $thing does not exist!', true);
		});

		Lua_helper.add_callback(lua, "TEXT_setString", function(tag:String, text:String) {
			var obj:FlxText = getTextObject(tag);
			if(obj != null) {
				obj.text = text;
				return true;
			}
			Dummy.debugPrint('TEXT_setString: Object $tag doesn\'t exist!', true);
			return false;
		});

		Lua_helper.add_callback(lua, "TEXT_setSize", function(tag:String, size:Int) {
			var obj:FlxText = getTextObject(tag);
			if(obj != null) {
				obj.size = size * (Prefs.lowDetail ? 1 : 2);
				return true;
			}
			Dummy.debugPrint('TEXT_setSize: Object $tag doesn\'t exist!', true);
			return false;
		});

		Lua_helper.add_callback(lua, "TEXT_setBorder", function(tag:String, size:Int, color:String) {
			var obj:FlxText = getTextObject(tag);
			if(obj != null) {
				var colorNum:Int = Std.parseInt(color);
				if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff$color');

				obj.borderSize = size * (Prefs.lowDetail ? 1 : 2);
				obj.borderColor = colorNum;
				return true;
			}
			Dummy.debugPrint('TEXT_setBorder: Object $tag doesn\'t exist!', true);
			return false;
		});

		Lua_helper.add_callback(lua, "TEXT_setStyle", function(tag:String, style:String, hexColor:String, ?size:Float = 1, ?quality:Float = 1) {
			function getStyle(type:String) {
				return switch(type.toLowerCase()) {
					case "shadow": FlxTextBorderStyle.SHADOW;
					case "outline": FlxTextBorderStyle.OUTLINE;
					case "outlinefast": FlxTextBorderStyle.OUTLINE_FAST;
					default: FlxTextBorderStyle.NONE;
				}
			}

			if (!Dummy.instance.texts.exists(tag)) {
				Dummy.debugPrint("TEXT_setStyle: Sprite does not exist.", true);
				return;
			}

			if (!hexColor.contains("0x")) hexColor = '0xFF$hexColor';

			var text:FlxText = Dummy.instance.texts.get(tag);
			text.setBorderStyle(getStyle(style), Std.parseInt(hexColor), size * (Prefs.lowDetail ? 1 : 2), quality);
		});

		Lua_helper.add_callback(lua, "TEXT_setColor", function(tag:String, color:String) {
			var obj:FlxText = getTextObject(tag);
			if(obj != null) {
				var colorNum:Int = Std.parseInt(color);
				if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff$color');

				obj.color = colorNum;
				return true;
			}
			Dummy.debugPrint('TEXT_setColor: Object $tag doesn\'t exist!', true);
			return false;
		});

		Lua_helper.add_callback(lua, "TEXT_setFont", function(tag:String, newFont:String) {
			var obj:FlxText = getTextObject(tag);
			if(obj != null) {
				obj.font = '${raw}assets/fonts/$newFont.ttf';
				return true;
			}
			Dummy.debugPrint('TEXT_setFont: Object $tag doesn\'t exist!', true);
			return false;
		});

		Lua_helper.add_callback(lua, "TEXT_setAlign", function(tag:String, alignment:String = 'left') {
			var obj:FlxText = getTextObject(tag);
			if(obj != null) {
				obj.alignment = LEFT;
				switch(alignment.trim().toLowerCase()) {
					case 'right':  obj.alignment = RIGHT;
					case 'center': obj.alignment = CENTER;
				}
				return true;
			}
			Dummy.debugPrint('TEXT_setAlign: Object $tag doesn\'t exist!', true);
			return false;
		});

		Lua_helper.add_callback(lua, "WIN_setWindowRes", function(?width:Int = 1280, ?height:Int = 720) {
			FlxG.resizeGame(width, height);
			FlxG.resizeWindow(width, height);
		});

		Lua_helper.add_callback(lua, "PROP_set", function(variable:String, value:Dynamic) {
			var thing:Array<String> = variable.split('.');
			if(thing.length > 1) {
				setVarInArray(gpltw(thing), thing[thing.length-1], value);
				return;
			}

			Dummy.debugPrint("PROP_set: Cannot access DUMMY variables!", true);
		});

		Lua_helper.add_callback(lua, "PROP_get", function(variable:String) {
			var result:Dynamic = null;
			var thing:Array<String> = variable.split('.');
			if(thing.length > 1) result = getVarInArray(gpltw(thing), thing[thing.length-1]);
			else Dummy.debugPrint("PROP_get: Cannot access DUMMY variables!", true);
			return result;
		});

		Lua_helper.add_callback(lua, "KEY_justPressed", function(?key:String) {
			if (key == null) return FlxG.keys.justPressed.ANY;
			return Reflect.getProperty(FlxG.keys.justPressed, key);
		});

		Lua_helper.add_callback(lua, "KEY_pressed", function(?key:String) {
			if (key == null) return FlxG.keys.pressed.ANY;
			return Reflect.getProperty(FlxG.keys.pressed, key);
		});

		Lua_helper.add_callback(lua, "MOUSE_clicked", function(?button:String) {
			return switch (button.toLowerCase()) {
				case "middle": FlxG.mouse.justPressedMiddle;
				case "right": FlxG.mouse.justPressedRight;
				case "any": (FlxG.mouse.justPressed ||FlxG.mouse.justPressedMiddle || FlxG.mouse.justPressedRight);
				default: FlxG.mouse.justPressed;
			}
		});

		Lua_helper.add_callback(lua, "MOUSE_pressed", function(?button:String) {
			return switch (button.toLowerCase()) {
				case "middle": FlxG.mouse.pressedMiddle;
				case "right": FlxG.mouse.pressedRight;
				case "any": (FlxG.mouse.pressed ||FlxG.mouse.pressedMiddle || FlxG.mouse.pressedRight);
				default: FlxG.mouse.pressed;
			}
		});

		Lua_helper.add_callback(lua, "PROP_setBlend", function(obj:String, blend:String = '') {
			function blendModeFromString(blend:String):BlendMode {
				return switch(blend.toLowerCase().trim()) {
					case 'add': ADD;
					case 'alpha': ALPHA;
					case 'darken': DARKEN;
					case 'difference': DIFFERENCE;
					case 'erase': ERASE;
					case 'hardlight': HARDLIGHT;
					case 'invert': INVERT;
					case 'layer': LAYER;
					case 'lighten': LIGHTEN;
					case 'multiply': MULTIPLY;
					case 'overlay': OVERLAY;
					case 'screen': SCREEN;
					case 'shader': SHADER;
					case 'subtract': SUBTRACT;
					default: NORMAL;
				}
			}

			var thinger = Dummy.instance.getLuaObject(obj);
			if(thinger!=null) {
				thinger.blend = blendModeFromString(blend);
				return true;
			}

			var thing:Array<String> = obj.split('.');
			var spr:FlxSprite = getObjectDirectly(thing[0]);
			if(thing.length > 1) spr = getVarInArray(gpltw(thing), thing[thing.length-1]);

			if(spr != null) {
				spr.blend = blendModeFromString(blend);
				return true;
			}
			Dummy.debugPrint('PROP_setBlend: Object $obj doesn\'t exist!', true);
			return false;
		});

		Lua_helper.add_callback(lua, "TWEEN_x", function(tag:String, vars:String, value:Dynamic, duration:Float, ?ease:String = 'linear') {
			var tween:Dynamic = tweenStuff(tag, vars);
			if(tween != null) {
				Dummy.instance.tweens.set(tag, FlxTween.tween(tween, {x: value}, duration, {ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						Dummy.callOnLuas('TWEEN_complete', [tag]);
						Dummy.instance.tweens.remove(tag);
					}
				}));
			} else Dummy.debugPrint('TWEEN_x: Couldn\'t find object: $vars', true);
		});

		Lua_helper.add_callback(lua, "TWEEN_y", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			var tween:Dynamic = tweenStuff(tag, vars);
			if(tween != null) {
				Dummy.instance.tweens.set(tag, FlxTween.tween(tween, {y: value}, duration, {ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						Dummy.callOnLuas('TWEEN_complete', [tag]);
						Dummy.instance.tweens.remove(tag);
					}
				}));
			} else Dummy.debugPrint('TWEEN_y: Couldn\'t find object: $vars', true);
		});

		Lua_helper.add_callback(lua, "TWEEN_angle", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			var tween:Dynamic = tweenStuff(tag, vars);
			if(tween != null) {
				Dummy.instance.tweens.set(tag, FlxTween.tween(tween, {angle: value}, duration, {ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						Dummy.callOnLuas('TWEEN_complete', [tag]);
						Dummy.instance.tweens.remove(tag);
					}
				}));
			} else Dummy.debugPrint('TWEEN_angle: Couldn\'t find object: $vars', true);
		});

		Lua_helper.add_callback(lua, "TWEEN_alpha", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			var tween:Dynamic = tweenStuff(tag, vars);
			if(tween != null) {
				Dummy.instance.tweens.set(tag, FlxTween.tween(tween, {alpha: value}, duration, {ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						Dummy.callOnLuas('TWEEN_complete', [tag]);
						Dummy.instance.tweens.remove(tag);
					}
				}));
			} else Dummy.debugPrint('TWEEN_alpha: Couldn\'t find object: $vars', true);
		});

		Lua_helper.add_callback(lua, "TWEEN_color", function(tag:String, vars:String, targetColor:String, duration:Float, ease:String) {
			var tween:Dynamic = tweenStuff(tag, vars);
			if(tween != null) {
				var color:Int = Std.parseInt(targetColor);
				if(!targetColor.startsWith('0x')) color = Std.parseInt('0xff$targetColor');

				var curColor:FlxColor = tween.color;
				curColor.alphaFloat = tween.alpha;
				Dummy.instance.tweens.set(tag, FlxTween.color(tween, duration, curColor, color, {ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						Dummy.instance.tweens.remove(tag);
						Dummy.callOnLuas('TWEEN_complete', [tag]);
					}
				}));
			} else Dummy.debugPrint('TWEEN_color: Couldn\'t find object: $vars', true);
		});

		Lua_helper.add_callback(lua, "PROP_setMouseVisibility", function(?show:Bool = true) {
			FlxG.mouse.enabled = show;
			FlxG.mouse.visible = show;
		});

		Lua_helper.add_callback(lua, "WIN_playSound", function(sound:String) {
			var n:String = '${raw}assets/sounds/$sound.ogg';

			if (!FileSystem.exists(n)) {
				Dummy.debugPrint('WIN_playSound: Couldn\'t find sound file: $n', true);
				return;
			}

			Dummy.playSound(n, sound);
		});

		Lua_helper.add_callback(lua, "PROP_moveToMouse", function(tag:String, ?speed:Int = 60) {
			if (Dummy.instance.sprites.exists(tag) || Dummy.instance.texts.exists(tag)){
				FlxVelocity.moveTowardsMouse(Dummy.instance.getLuaObject(tag), speed);
				return;
			}

			Dummy.debugPrint("PROP_moveToMouse: Sprite does not exist, did you make a typo?", true);
		});

		Lua_helper.add_callback(lua, "WIN_popup", function(desc:String = "", ?title:String = "") {
			if (title == "") title = PlayState.modName;

			if (desc == "") {
				Dummy.debugPrint("WIN_popup: Argument 2: Desc cannot be empty!", true);
				return;
			}

			Application.current.window.alert(desc, title);
		});

		Lua_helper.add_callback(lua, "RAND_int", function(?min:Int = 1, ?max:Int = 10) return FlxG.random.int(min, max));

		Lua_helper.add_callback(lua, "RAND_float", function(?min:Float = 0, ?max:Float = 1) return FlxG.random.float(min, max));

		Lua_helper.add_callback(lua, "RAND_bool", function(?chance:Float = 50) {
			if (chance > 100) chance = 100;
			if (chance < 0)   chance = 0;

			return FlxG.random.bool(chance);
		});

		Lua_helper.add_callback(lua, "WIN_gc", function() openfl.system.System.gc());

		Lua_helper.add_callback(lua, "SPRITE_graphic", function(obj:String, ?width:Int = 256, ?height:Int = 256, ?color:String = "FFFFFF") {
			var colorNum:Int = Std.parseInt(color);
			if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff$color');

			var spr:FlxSprite = Dummy.instance.getLuaObject(obj,false);
			if(spr!=null) {
				Dummy.instance.getLuaObject(obj,false).makeGraphic(width, height, colorNum);
				return;
			}

			var object:FlxSprite = Reflect.getProperty(Dummy.instance, obj);
			if(object != null) object.makeGraphic(width, height, colorNum);
		});

		Lua_helper.add_callback(lua, "PROP_center", function(obj:String, ?pos:String = 'xy') {
			var spr:FlxSprite = Dummy.instance.getLuaObject(obj);

			if(spr == null) {
				var thing:Array<String> = obj.split('.');
				spr = getObjectDirectly(thing[0]);
				if(thing.length > 1) spr = getVarInArray(gpltw(thing), thing[thing.length-1]);
			}

			if(spr != null) {
				switch(pos.trim().toLowerCase()) {
					case 'x': spr.screenCenter(X);
					case 'y': spr.screenCenter(Y);
					default:  spr.screenCenter(XY);
				}
				return;
			}

			Dummy.debugPrint('PROP_center: Object $obj doesn\'t exist!', true);
		});

		Lua_helper.add_callback(lua, "STR_starts", function(str:String, start:String) return str.startsWith(start));
		Lua_helper.add_callback(lua, "STR_ends", function(str:String, end:String) return str.endsWith(end));
		Lua_helper.add_callback(lua, "STR_split", function(str:String, split:String) return str.split(split));
		Lua_helper.add_callback(lua, "STR_trim", function(str:String) return str.trim());

		Lua_helper.add_callback(lua, "PROP_scale", function(obj:String, x:Float, y:Float) {
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
			Dummy.debugPrint('PROP_scale: Couldnt find object: $obj', true);
		});

		Lua_helper.add_callback(lua, "TIMER_run", function(tag:String, ?time:Float = 1, ?loops:Int = 1) {
			cancelTimer(tag);
			Dummy.instance.timers.set(tag, new FlxTimer().start(time, function(tmr:FlxTimer) {
				if(tmr.finished) Dummy.instance.timers.remove(tag);
				Dummy.callOnLuas('TIMER_complete', [tag, tmr.loops, tmr.loopsLeft]);
			}, loops));
		});

		Lua_helper.add_callback(lua, "TIMER_cancel", function(tag:String) cancelTimer(tag));

		Lua_helper.add_callback(lua, "TWEEN_cancel", function(tag:String) cancelTween(tag));

		Lua_helper.add_callback(lua, "IO_read", function(file:String = ''):String {
			var n:String = '${raw}assets/data/$file';
			if (file == '') {
				Dummy.debugPrint("IO_read: File argument is empty!", true);
				return "";
			}

			if (!FileSystem.exists(n)) {
				Dummy.debugPrint('IO_read: File does not exist on $n! Did you make a typo?', true);
				return "";
			}
				
			return File.getContent(n);
		});

		Lua_helper.add_callback(lua, "WIN_setWindowName", function(name:String) Main.changeWindowName(name));

		Lua_helper.add_callback(lua, "PROP_objOverlap", function(obj1:String, obj2:String) {
			var namesArray:Array<String> = [obj1, obj2];
			var objectsArray:Array<FlxSprite> = [];
			for (i in 0...namesArray.length) {
				var thinhg = Dummy.instance.getLuaObject(namesArray[i]);
				if(thinhg != null) objectsArray.push(thinhg); else objectsArray.push(Reflect.getProperty(Dummy.instance, namesArray[i]));
			}

			return !objectsArray.contains(null) && FlxG.overlap(objectsArray[0], objectsArray[1]);
		});

		Lua_helper.add_callback(lua, "DEBUG_clear", function() Dummy.clearLog());

		Lua_helper.add_callback(lua, "WIN_resetRes", function() Utils.setDefaultResolution());

		Lua_helper.add_callback(lua, "GAME_exit", function() Dummy.exit());

		Lua_helper.add_callback(lua, "PROP_getDist", function(tag1:String, tag2:String):Float {
			var spr1 = Dummy.instance.getLuaObject(tag1);
			var spr2 = Dummy.instance.getLuaObject(tag2);

			if (spr1 != null || spr2 != null) {
				Dummy.debugPrint('PROP_getDist: One of the Sprites does not exist! (arg1: ${spr1.alive}, arg2: ${spr2.alive})', true);
				return 0;
			}

			return FlxMath.distanceBetween(spr1, spr2);
		});

		Lua_helper.add_callback(lua, "WIN_setIcon", function(image:String) {
			var path:String = '${raw}assets/images/$image.png';

			if (FileSystem.exists(path)) {
				Application.current.window.setIcon(Image.fromFile(path));
				return;
			}

			Dummy.debugPrint('WIN_setIcon: Couldn\'t find file: $path');
		});

		Lua_helper.add_callback(lua, "WIN_setClipboard", function(text:String) Clipboard.text = text);

		Lua_helper.add_callback(lua, "MOUSE_released", function(?button:String):Bool {
			return switch (button.toLowerCase()) {
				case "middle": FlxG.mouse.releasedMiddle;
				case "right": FlxG.mouse.releasedRight;
				case "any": (FlxG.mouse.released ||FlxG.mouse.releasedMiddle || FlxG.mouse.releasedRight);
				default: FlxG.mouse.released;
			}
		});

		Lua_helper.add_callback(lua, "MOUSE_justReleased", function(?button:String):Bool {
			return switch (button.toLowerCase()) {
				case "middle": FlxG.mouse.justReleasedMiddle;
				case "right": FlxG.mouse.justReleasedRight;
				case "any": (FlxG.mouse.justReleased ||FlxG.mouse.justReleasedMiddle || FlxG.mouse.justReleasedRight);
				default: FlxG.mouse.justReleased;
			}
		});

		Lua_helper.add_callback(lua, "KEY_released", function(?key:String):Bool {
			if (key == null) return FlxG.keys.released.ANY;
			return Reflect.getProperty(FlxG.keys.released, key);
		});

		Lua_helper.add_callback(lua, "KEY_JustReleased", function(?key:String):Bool {
			if (key == null) return FlxG.keys.justReleased.ANY;
			return Reflect.getProperty(FlxG.keys.justReleased, key);
		});

		Lua_helper.add_callback(lua, "STR_toBytes",       function(bytes:Float, precision:Int = 2):String return FlxStringUtil.formatBytes(bytes, precision));
		Lua_helper.add_callback(lua, "STR_toMoney",       function(amount:Float, showDecimal:Bool = true, englishStyle:Bool = true):String return FlxStringUtil.formatMoney(amount, showDecimal, englishStyle));
		Lua_helper.add_callback(lua, "STR_toTime",        function(seconds:Float, showMS:Bool = false):String return FlxStringUtil.formatTime(seconds, showMS));
		Lua_helper.add_callback(lua, "STR_toTitle",       function(str:String):String return FlxStringUtil.toTitleCase(str));
		Lua_helper.add_callback(lua, "STR_toUnderscore",  function(str:String):String return FlxStringUtil.toUnderscoreCase(str));
		Lua_helper.add_callback(lua, "PROP_distanceTo",   function(sprite:String):Int {
			var spr = Dummy.instance.getLuaObject(sprite);

			if (spr == null) {
				Dummy.debugPrint('PROP_distanceTo: Sprite "$sprite" doesn\'t exist!', true);
				return 0;
			}

			return FlxMath.distanceToMouse(spr);
		});

		Lua_helper.add_callback(lua, "NUM_decimals", function(num:Float):Int return FlxMath.getDecimals(num));

		Lua_helper.add_callback(lua, "PROP_setBright", function(tag:String, ?brightness:Float = 0) {
			var spr = Dummy.instance.getLuaObject(tag);

			if (spr == null) {
				Dummy.debugPrint('PROP_setBright: Sprite tag "$tag" does not exist, did you make a typo?', true);
				return;
			}

			FlxSpriteUtil.setBrightness(spr, brightness);
		});

		Lua_helper.add_callback(lua, "MOUSE_overlaps", function(tag:String):Bool {
			var spr = Dummy.instance.getLuaObject(tag);

			if (spr == null) {
				Dummy.debugPrint('MOUSE_overlaps: Sprite tag "$tag" does not exist, did you make a typo?', true);
				return false;
			}

			return FlxG.mouse.overlaps(spr);
		});

		Lua_helper.add_callback(lua, "DATE_day",        function():Int    return Date.now().getDate());
		Lua_helper.add_callback(lua, "DATE_weekDay",    function():Int    return Date.now().getDay());
		Lua_helper.add_callback(lua, "DATE_fullYear",   function():Int    return Date.now().getFullYear());
		Lua_helper.add_callback(lua, "DATE_hours",      function():Int    return Date.now().getHours());
		Lua_helper.add_callback(lua, "DATE_minutes",    function():Int    return Date.now().getMinutes());
		Lua_helper.add_callback(lua, "DATE_month",      function():Int    return Date.now().getMonth());
		Lua_helper.add_callback(lua, "DATE_seconds",    function():Int    return Date.now().getSeconds());
		Lua_helper.add_callback(lua, "DATE_time",       function():Float  return Date.now().getTime());
		Lua_helper.add_callback(lua, "DATE_timeFormat", function():String return Date.now().toString());

		Lua_helper.add_callback(lua, "IO_File", function(name:String = ""):String {
			if (name == "") name = "main";
			return '${raw}source/$name'.replace("/", ".");
		});

		Lua_helper.add_callback(lua, "IO_saveFile", function(fileName:String, content:String = ""):Bool {
			var pathFile:String = '${raw}assets/data/$fileName';
			try {
				File.saveContent(pathFile, content);
				return true;
			} catch(e) Dummy.debugPrint('IO_saveFile: Cannot save file on location: $pathFile', true);
			return false;
		});

		Lua_helper.add_callback(lua, "IO_deleteFile", function(fileName:String):Bool {
			var pathFile:String = '${raw}assets/data/$fileName';
			try {
				FileSystem.deleteFile(pathFile);
				return true;
			} catch(e) Dummy.debugPrint('IO_deleteFile: Cannot delete file on location: $pathFile', true);
			return false;
		});

		Lua_helper.add_callback(lua, "DEBUG_enable",  function(?allow:Bool = false)  Dummy.allowDebug = allow);
		Lua_helper.add_callback(lua, "IO_fileExists", function(filePath:String):Bool return FileSystem.exists('${raw}assets/data/$filePath'));
		Lua_helper.add_callback(lua, "WIN_moveWin",   function(xPos:Int, yPos:Int) Application.current.window.move(xPos, yPos));

		Lua_helper.add_callback(lua, "GAME_switchState", function(file:String) {
			var path:String = '${raw}source/$file.lua';

			if (FileSystem.exists(path)) {
				Dummy.switchState(path);
				return;
			}

			Dummy.debugPrint('GAME_switchState: Couldn\'t find file: $path');
		});

		Lua_helper.add_callback(lua, "IO_mkdir", function(folder:String) FileSystem.createDirectory('${raw}assets/data/$folder'));


		Lua_helper.add_callback(lua, "IO_notify", function(desc:String) {
			function getWindowsVersion() {
				var windowsVersions:Map<String, Int> = [
					"Windows 11" => 11,
					"Windows 10" => 10,
					"Windows 8.1" => 8,
					"Windows 8" => 8,
					"Windows 7" => 7,
				];

				var platformLabel = System.platformLabel;
				var words = platformLabel.split(" ");
				var windowsIndex = words.indexOf("Windows");
				var result = "";
				if (windowsIndex != -1 && windowsIndex < words.length - 1) result = words[windowsIndex] + " " + words[windowsIndex + 1];

				if (windowsVersions.exists(result)) return windowsVersions.get(result);

				return 0;
			}
		
			var powershellCommand = "powershell -Command \"& {$ErrorActionPreference = 'Stop';"
			+ "$title = '"
			+ desc
			+ "';"
			+ "[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null;"
			+ "$template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText01);"
			+ "$toastXml = [xml] $template.GetXml();"
			+ "$toastXml.GetElementsByTagName('text').AppendChild($toastXml.CreateTextNode($title)) > $null;"
			+ "$xml = New-Object Windows.Data.Xml.Dom.XmlDocument;"
			+ "$xml.LoadXml($toastXml.OuterXml);"
			+ "$toast = [Windows.UI.Notifications.ToastNotification]::new($xml);"
			+ "$toast.Tag = 'Test1';"
			+ "$toast.Group = 'Test2';"
			+ "$notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('"
			+ PlayState.modName
			+ "');"
			+ "$notifier.Show($toast);}\"";

			var vers:Int = getWindowsVersion();
			if (desc != null && desc != "")
				new HiddenProcess(powershellCommand);
			else
				Dummy.debugPrint('IO_notify: Cannot send notification because desc is empty!', true);
		});

		Lua_helper.add_callback(lua, "DISCORD_setPresence", function(?state:String = "", ?description:String = "") {
			if (state == "")       state = Dummy.rpcDetails[0];
			if (description == "") description = Dummy.rpcDetails[1];
			
			DiscordRPC.changePresence(state, description);
		});

		Lua_helper.add_callback(lua, "GAME_openURL",      function(url:String)  FlxG.openURL(url));
		Lua_helper.add_callback(lua, "IO_openFileToWin",  function(path:String) System.openFile('${raw}assets/data/$path'));
		Lua_helper.add_callback(lua, "WIN_stopAllSounds", function() Pause.killSounds(true));
		Lua_helper.add_callback(lua, "IO_readDirectory",  function(dir:String):Array<String> {
			var path:String = '$raw$dir';
			
			return FileSystem.readDirectory(path);
		});

		Lua_helper.add_callback(lua, "PROP_update", function(obj:String) {
			if(Dummy.instance.getLuaObject(obj) != null) {
				var spr = Dummy.instance.getLuaObject(obj);
				spr.updateHitbox();
				return;
			}

			Dummy.debugPrint('PROP_update: Could\'t find sprite: $obj', true);
		});

		Lua_helper.add_callback(lua, "PROP_exists", function(tag:String):Bool  return Dummy.instance.getLuaObject(tag) != null);

		Lua_helper.add_callback(lua, "SAVE_init", function(name:String, ?folder:String = 'luapps') {
			if(!Dummy.instance.saves.exists(name)) {
				var save:FlxSave = new FlxSave();
				save.bind(name, '${Utils.getSavePath()}/$folder');
				Dummy.instance.saves.set(name, save);
				return;
			}
			Dummy.debugPrint('SAVE_init: Save file already initialized: $name');
		});

		Lua_helper.add_callback(lua, "SAVE_flush", function(name:String) {
			if(Dummy.instance.saves.exists(name)) {
				Dummy.instance.saves.get(name).flush();
				return;
			}
			Dummy.debugPrint('SAVE_flush: Save file not initialized: $name', true);
		});

		Lua_helper.add_callback(lua, "SAVE_getData", function(name:String, field:String) {
			if(Dummy.instance.saves.exists(name)) {
				var retVal:Dynamic = Reflect.field(Dummy.instance.saves.get(name).data, field);
				return retVal;
			}
			Dummy.debugPrint('SAVE_getData: Save file not initialized: $name', true);
			return null;
		});
		
		Lua_helper.add_callback(lua, "SAVE_setData", function(name:String, field:String, value:Dynamic) {
			if(Dummy.instance.saves.exists(name)) {
				Reflect.setField(Dummy.instance.saves.get(name).data, field, value);
				return;
			}
			Dummy.debugPrint('SAVE_setData: Save file not initialized: $name', true);
		});
	}

	public static var lastCalledScript:LuaEngine = null;
	public function call(func:String, args:Array<Dynamic>):Dynamic {
		function getErrorMessage(status:Int):String {
			var v:String = Lua.tostring(lua, -1);
			Lua.pop(lua, 1);
	
			if (v != null) v = v.trim();
			if (v == null || v == "") {
				return switch(status) {
					case Lua.LUA_ERRRUN: "Runtime Error";
					case Lua.LUA_ERRMEM: "Memory Allocation Error";
					case Lua.LUA_ERRERR: "Critical Error";
					default:             "Unknown Error";
				}
			}
	
			return v;
		}

		function typeToString(type:Int):String {
			switch(type) {
				case Lua.LUA_TBOOLEAN:  return "boolean";
				case Lua.LUA_TNUMBER:   return "number";
				case Lua.LUA_TSTRING:   return "string";
				case Lua.LUA_TTABLE:    return "table";
				case Lua.LUA_TFUNCTION: return "function";
			}
			if (type <= Lua.LUA_TNIL) return "nil";
			return "unknown";
		}

		if(closed) return Function_Continue;

		lastCalledScript = this;
		try {
			if(lua == null) return Function_Continue;

			Lua.getglobal(lua, func);
			var type:Int = Lua.type(lua, -1);

			if (type != Lua.LUA_TFUNCTION) {
				if (type > Lua.LUA_TNIL) Dummy.debugPrint('$func: attempt to call a ${typeToString(type)} value', true);

				Lua.pop(lua, 1);
				return Function_Continue;
			}

			for (arg in args) Convert.toLua(lua, arg);
			var status:Int = Lua.pcall(lua, args.length, 1, 0);
			// Checks if it's not successful, then show a error.
			if (status != Lua.LUA_OK) {
				var error:String = getErrorMessage(status);
				Dummy.debugPrint('$func: $error', true);
				return Function_StopLua;
			}

			var result:Dynamic = cast Convert.fromLua(lua, -1);
			if (result == null) result = Function_Continue;

			Lua.pop(lua, 1);
			return result;
		} catch (e:Dynamic) trace(e);
		return Function_Continue;
	}


	inline static function getTextObject(name:String):FlxText return Dummy.instance.texts.exists(name) ? Dummy.instance.texts.get(name) : Reflect.getProperty(Dummy.instance, name);

	function tweenStuff(tag:String, vars:String) {
		cancelTween(tag);
		var variables:Array<String> = vars.split('.');
		var sexyProp:Dynamic = getObjectDirectly(variables[0]);
		if(variables.length > 1) sexyProp = getVarInArray(gpltw(variables), variables[variables.length-1]);
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
		return switch(ease.toLowerCase().trim()) {
			case 'backin': FlxEase.backIn;
			case 'backinout': FlxEase.backInOut;
			case 'backout': FlxEase.backOut;
			case 'bouncein': FlxEase.bounceIn;
			case 'bounceinout': FlxEase.bounceInOut;
			case 'bounceout': FlxEase.bounceOut;
			case 'circin': FlxEase.circIn;
			case 'circinout': FlxEase.circInOut;
			case 'circout': FlxEase.circOut;
			case 'cubein': FlxEase.cubeIn;
			case 'cubeinout': FlxEase.cubeInOut;
			case 'cubeout': FlxEase.cubeOut;
			case 'elasticin': FlxEase.elasticIn;
			case 'elasticinout': FlxEase.elasticInOut;
			case 'elasticout': FlxEase.elasticOut;
			case 'expoin': FlxEase.expoIn;
			case 'expoinout': FlxEase.expoInOut;
			case 'expoout': FlxEase.expoOut;
			case 'quadin': FlxEase.quadIn;
			case 'quadinout': FlxEase.quadInOut;
			case 'quadout': FlxEase.quadOut;
			case 'quartin': FlxEase.quartIn;
			case 'quartinout': FlxEase.quartInOut;
			case 'quartout': FlxEase.quartOut;
			case 'quintin': FlxEase.quintIn;
			case 'quintinout': FlxEase.quintInOut;
			case 'quintout': FlxEase.quintOut;
			case 'sinein': FlxEase.sineIn;
			case 'sineinout': FlxEase.sineInOut;
			case 'sineout': FlxEase.sineOut;
			case 'smoothstepin': FlxEase.smoothStepIn;
			case 'smoothstepinout': FlxEase.smoothStepInOut;
			case 'smoothstepout': FlxEase.smoothStepInOut;
			case 'smootherstepin': FlxEase.smootherStepIn;
			case 'smootherstepinout': FlxEase.smootherStepInOut;
			case 'smootherstepout': FlxEase.smootherStepOut;
			default: FlxEase.linear;
		}
	}

	public static function gpltw(thing:Array<String>, ?checkForTextsToo:Bool = true, ?getProperty:Bool=true):Dynamic {
		var stuff:Dynamic = getObjectDirectly(thing[0], checkForTextsToo);
		var end = thing.length;
		if(getProperty)end=thing.length-1;

		for (i in 1...end) stuff = getVarInArray(stuff, thing[i]);
		return stuff;
	}

	public static function getObjectDirectly(objectName:String, ?checkForTextsToo:Bool = true):Dynamic {
		var thing:Dynamic = Dummy.instance.getLuaObject(objectName, checkForTextsToo);
		if (thing == null) thing = getVarInArray(Dummy.instance, objectName);

		return thing;
	}

	public static function getVarInArray(instance:Dynamic, variable:String):Any {
		var Stuff:Array<String> = variable.split('[');
		if(Stuff.length > 1) {
			var blah:Dynamic = null;
			if(Dummy.instance.variables.exists(Stuff[0])) {
				var retVal:Dynamic = Dummy.instance.variables.get(Stuff[0]);
				if(retVal != null) blah = retVal;
			} else blah = Reflect.getProperty(instance, Stuff[0]);

			for (i in 1...Stuff.length) {
				var leNum:Dynamic = Stuff[i].substr(0, Stuff[i].length - 1);
				blah = blah[leNum];
			}
			return blah;
		}

		if(Dummy.instance.variables.exists(variable)) {
			var retVal:Dynamic = Dummy.instance.variables.get(variable);
			if(retVal != null) return retVal;
		}

		return Reflect.getProperty(instance, variable);
	}

	public static function setVarInArray(instance:Dynamic, variable:String, value:Dynamic):Any {
		var Stuff:Array<String> = variable.split('[');
		if(Stuff.length > 1) {
			var blah:Dynamic = null;
			if(Dummy.instance.variables.exists(Stuff[0])) {
				var retVal:Dynamic = Dummy.instance.variables.get(Stuff[0]);
				if(retVal != null) blah = retVal;
			} else blah = Reflect.getProperty(instance, Stuff[0]);

			for (i in 1...Stuff.length) {
				var leNum:Dynamic = Stuff[i].substr(0, Stuff[i].length - 1);
				if(i >= Stuff.length-1) blah[leNum] = value;
				else blah = blah[leNum];
			}
			return blah;
		}
			
		if(Dummy.instance.variables.exists(variable)) {
			Dummy.instance.variables.set(variable, value);
			return true;
		}

		Reflect.setProperty(instance, variable, value);
		return true;
	}

	public function set(variable:String, data:Dynamic) {
		if (lua == null) return;

		Convert.toLua(lua, data);
		Lua.setglobal(lua, variable);
	}
}

class ModchartSprite extends FlxSprite {
	public var wasAdded:Bool = false;

	public function new(?x:Float = 0, ?y:Float = 0) {
		super(x, y);
		antialiasing = Prefs.antiAliasing;
	}
}