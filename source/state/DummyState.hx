package state;

import openfl.events.Event;

class Dummy extends FlxState {
	public static var instance:Dummy;
	
	public var sprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var texts:Map<String, FlxText> = new Map<String, FlxText>();
	public var variables:Map<String, Dynamic> = new Map();
	public var tweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var timers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var saves:Map<String, FlxSave> = new Map<String, FlxSave>();
	public static var luaArray:Array<LuaEngine> = [];
	public static var debugger:Array<FlxText> = [];
	
	public static var channels:Array<SoundChannel> = [];
	public static var positions:Array<Float> = [];
    public static var sounds:Array<Sound> = [];
	public static var startTime:Float = 0;
	public static var pausedTime:Float = 0;
	public static var allowDebug:Bool = false;
	public static var rpcDetails:Array<String> = ['', ''];

	static var oldTime:Float = 0;

	override public function create() {
		rpcDetails[0] = PlayState.modName;
		rpcDetails[1] = 'By: ${PlayState.author} | Version: ${PlayState.appVersion}';
		DiscordRPC.changePresence(rpcDetails[0], rpcDetails[1]);

		instance   = this;

		allowDebug = false;
		oldTime    = Date.now().getTime();
		startTime  = 0;
		pausedTime = 0;

		updateVars();
		callOnLuas("create");
		super.create();
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		Dummy.updateVars();
		for (text in debugger) add(text);

		callOnLuas("update", [elapsed]);

		if (FlxG.keys.justPressed.ESCAPE) openSubState(new Pause());

		if (FlxG.keys.justPressed.R && Prefs.restartByR) {
			sprites = [];
			texts = [];
			variables = [];
			tweens = [];
			luaArray = [];
			debugger = [];
			Pause.killSounds();

			luaArray.push(new LuaEngine('${PlayState.modRaw}source/main.lua'));
			FlxG.switchState(Dummy.new);
		}

		for (channel in channels) {
            if (channel != null) {
                var transform:SoundTransform = channel.soundTransform;
                transform.volume = FlxG.sound.volume; // Apply new volume
                channel.soundTransform = transform;
            }
        }
	}

	public static function playSound(path:String, soundName:String) {
        var sound:Sound = Sound.fromFile(path);
        var channel:SoundChannel = sound.play();
        if (channel != null) {
            var transform:SoundTransform = channel.soundTransform;
            transform.volume = FlxG.sound.volume;
            channel.soundTransform = transform;
            
            channels.push(channel);
            positions.push(0); // Start at position 0
            sounds.push(sound);

			channel.addEventListener(Event.SOUND_COMPLETE, e -> callOnLuas("soundComplete", [soundName]));
        }
    }

	public static function exit(restartOnly:Bool = false) {
		Dummy.resetVars();

		Application.current.window.setIcon(Image.fromFile("assets/images/icons/iconOG.png"));
		if (!restartOnly) FlxG.resetGame();
	}

	public static function switchState(path:String) {
		Dummy.resetVars();

		luaArray.push(new LuaEngine(path));
		Dummy.updateVars();
		Dummy.callOnLuas("create");
	}

	public static function debugPrint(text:String, warn:Bool = false) {
		if (!allowDebug && warn) return;

		var l:Int = debugger.length;
		text = (warn ? "[WARN] " : "") + text;

		if (l == 37) {
			debugger[0].destroy();
			debugger.remove(debugger[0]);

			var i:Int = 0;
			for (tex in debugger) {
				tex.y = 20 * i;
				i++;
			}

			l--;
		}

		if (text.length > 91) {
			Sys.println('${PlayState.modName}: $text');
			text = text.substr(0, 88);
			text += "...\n(Full Debug if the terminal is launched!)";
		}

		var curText:Array<String> = text.split("\n");
		for (text in curText) {
			debugger.push(new UtilText(0, 16 * l, 1280 * (Prefs.lowDetail ? 1 : 2), text, 14, null, null, null, warn ? FlxColor.YELLOW : FlxColor.WHITE, 'assets/fonts/debug.ttf'));
			debugger[l].borderSize = 0;
			l = debugger.length;
		}
	}

	public static function updateVars() {
		Dummy.set('GAME_author',    PlayState.author);
		Dummy.set('CLIPBOARD_item', Clipboard.text);
		Dummy.set('GAME_fps',       FPSCounter.currentFPS);
		Dummy.set('WIN_fullscreen', FlxG.fullscreen);
		Dummy.set('WIN_height',     Application.current.window.height);
		Dummy.set('GAME_lowDetail', Prefs.lowDetail);
		Dummy.set('WIN_memory',     FPSCounter.curMemory);
		Dummy.set('WIN_mempeak',    FPSCounter.curMaxMemory);
		Dummy.set('GAME_modName',   PlayState.modName);
		Dummy.set('IO_modRaw',      PlayState.modRaw);
		Dummy.set('MOUSE_moved',    FlxG.mouse.justMoved);
		Dummy.set('MOUSE_wheel',    FlxG.mouse.wheel);
		Dummy.set('MOUSE_x',        FlxG.mouse.x);
		Dummy.set('MOUSE_y',        FlxG.mouse.y);
		Dummy.set('GAME_time',      (Date.now().getTime() - (Dummy.oldTime + Dummy.startTime)) / 1000);
		Dummy.set('GAME_version',   Main.luversion);
		Dummy.set('WIN_width',      Application.current.window.width);
		Dummy.set('WIN_x',          Application.current.window.x);
		Dummy.set('WIN_y',          Application.current.window.y);
	}

	public static function clearLog() {
		for (text in Dummy.debugger) text.destroy();
			
		Dummy.debugger = [];
	}

	public static function callOnLuas(event:String, args:Array<Dynamic> = null, ignoreStops = true, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
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

	public static function set(variable:String, arg:Dynamic) for (i in 0...luaArray.length) luaArray[i].set(variable, arg);

	public function getLuaObject(tag:String, text:Bool=true):FlxSprite {
		if (sprites.exists(tag)) return sprites.get(tag);
		if (text && texts.exists(tag)) return texts.get(tag);
		if (variables.exists(tag)) return variables.get(tag);
		return null;
	}

	static function resetVars() {
		try {
			clearLog();

			Dummy.instance.sprites.clear();
			Dummy.instance.texts.clear();
			Dummy.instance.variables.clear();
			Dummy.instance.tweens.clear();
			Dummy.instance.timers.clear();
			Dummy.luaArray = [];
			debugger = [];

			Pause.killSounds(true);
			Dummy.sounds = [];
			Dummy.channels = [];
			Dummy.positions = [];
		} catch(e:Dynamic) {} // Failed to do those, prevent a crash.
	}
}

class Pause extends FlxSubState {
	public function new() super(0x00000000);

	private var buttonSpr:Array<FlxSprite> = [];
	private var buttonTxt:Array<FlxText> = [];
	
	private var pauseText:UtilText = new UtilText(0, 26, 1280, "Pause.", 96, CENTER);
	private var music:FlxSound = new FlxSound();
	private var blackBG:FlxSprite = new FlxSprite();

	var isMouseHidden:Bool = FlxG.mouse.enabled;
	var isGoing:Bool = true;

	override public function create() {
		DiscordRPC.changePresence('[PAUSE] ${Dummy.rpcDetails[0]}', '[PAUSE] ${Dummy.rpcDetails[1]}');
		Dummy.pausedTime = Date.now().getTime();
		killSounds();

		blackBG.makeGraphic(1920, 1080, FlxColor.BLACK);
		blackBG.alpha = 0;
		FlxTween.tween(blackBG, {alpha: 0.6}, 0.5);
		add(blackBG);

		if (FlxG.sound.music != null) FlxG.sound.music.pause();

		FlxG.mouse.enabled = true;
		FlxG.mouse.visible = true;

		pauseText.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.GRAY, PlayState.qSize, PlayState.qSize);
		pauseText.alpha = 0;
		FlxTween.tween(pauseText, {alpha: 1}, 0.5, {onComplete: e -> isGoing = false});
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

			buttonTxt.push(new UtilText((-(stuffies.length*200) + (i * 400)) + 200, 555, 1280, stuff, 48, CENTER));
			buttonTxt[i].alpha = 0;
			FlxTween.tween(buttonTxt[i], {alpha: 1}, 0.5);
			add(buttonTxt[i]);
		}

		var modN:FlxText = new UtilText(-15, -20, 1280, PlayState.modName, 36, RIGHT);
		modN.bold = true;
		modN.alpha = 0;
		new FlxTimer().start(0.35, e -> FlxTween.tween(modN, {y: 10, alpha: 1}, 0.25));
		add(modN);

		var modA:FlxText = new UtilText(-15, 20, 1280, PlayState.author, 36, RIGHT);
		modA.bold = true;
		modA.alpha = 0;
		new FlxTimer().start(0.55, e -> FlxTween.tween(modA, {y: 50, alpha: 1}, 0.25));
		add(modA);

		music.loadEmbedded('assets/music/settings.ogg');
		music.fadeIn(8);
		music.looped = true;
		music.play();

		super.create();
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

							var hit:Bool = false;
							for (sprite in members)
								FlxTween.tween(sprite, {alpha: 0}, 0.5, {onComplete: e -> {
									if (hit) return;
									hit = true;

									for (i in 0...Dummy.sounds.length) {
										if (Dummy.sounds[i] != null) {
											if (Dummy.channels[i] != null) {
												Dummy.channels[i].stop(); // Stop old channel if it somehow survived
												Dummy.channels[i] = null;
											}
											var channel:SoundChannel = Dummy.sounds[i].play(Dummy.positions[i]); // Resume from saved position
											if (channel != null) {
												var transform:SoundTransform = channel.soundTransform;
												transform.volume = FlxG.sound.volume;
												channel.soundTransform = transform;
												
												Dummy.channels[i] = channel;
											}
										}
									}

									DiscordRPC.changePresence(Dummy.rpcDetails[0], Dummy.rpcDetails[1]);
									Dummy.startTime += Date.now().getTime() - Dummy.pausedTime;
									close();
								}});

	
						case "Exit App":
							for (sprite in members) FlxTween.tween(sprite, {alpha: 0}, 0.5);

							FlxTween.tween(blackBG, {alpha: 1}, 0.5, {onComplete: e -> Dummy.exit()});
					}
				}
	
				i++;
			}
		}
	}

	public static function killSounds(?killSounds:Bool = false) {
		for (i in 0...Dummy.channels.length) {
            if (Dummy.channels[i] != null) {
                Dummy.positions[i] = Dummy.channels[i].position; // Save position
                Dummy.channels[i].stop(); // Stop the sound
                Dummy.channels[i] = null;
				if (killSounds) Dummy.sounds[i] = null;
            }
        }
	}
}