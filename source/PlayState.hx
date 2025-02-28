package;

import lime.app.Application;
import haxe.Timer;
import openfl.media.Sound;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import sys.FileSystem;
import sys.io.File;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxG;
import openfl.display.BitmapData;
import LuaEngine;
import haxe.Json;

class PlayState extends FlxState
{
	public static var lolArray:Array<LuaEngine> = [];
	public static var author:String;
	public static var modName:String;
	public static var modRaw:String;

	var spriteIDList:Array<Array<FlxSprite>> = [];
	var spriteYPos:Array<Float> = [];
	var textIDList:Array<Array<FlxText>> = [];
	var textYPos:Array<Float> = [];
	var luaLists:Array<Array<String>> = [];

	var optionsBG:FlxSprite = new FlxSprite();
	var options:FlxSprite = new FlxSprite();
	var mouseDistance:FlxSprite = new FlxSprite();
	var sleepy:FlxSprite = new FlxSprite();
	var optionsText:FlxText = new FlxText(1104, 642, 1920, "Options", 16);

	var allowTween:Bool = false;
	var yPos:Float = -5;
	var oldYPos:Float = 0;
	var mouseYPos:Float = 0;
	var mouseScroll:Float = 0;
	var oldTime:Float = 0;
	var tickLeft:Int = 5;
	var choice:Int = 0;
	var oldChoice:Int = 0;
	var disableMoving:Bool = false;
	
	override public function create()
	{
		super.create();

		Main.changeWindowName("Applications");

		if (modRaw != "") {
			modRaw = "";
			//if (FlxG.sound.music.playing) FlxG.sound.music.stop();
			FlxG.resetState();
		}

		FlxG.autoPause = false;
		FlxG.resizeGame(1280, 720);
		FlxG.resizeWindow(1280, 720);
		FlxG.sound.muted = false;
		FlxG.mouse.enabled = true;
		FlxG.mouse.visible = true;
		FlxG.sound.playMusic("assets/music/menu.ogg", 1, true);

		oldTime = Timer.stamp();

		if (!FileSystem.exists("mods/")) FileSystem.createDirectory("mods/");

		var gray:FlxSprite = new FlxSprite().makeGraphic(1920, 1080, Std.parseInt('0xFF222222'));
		add(gray);

		generate();

		optionsBG.makeGraphic(150, 60, Std.parseInt('0xFFA78080'));
		optionsBG.x = 1095;
		optionsBG.y = 635;
		add(optionsBG);

		options.makeGraphic(140, 50, Std.parseInt('0xFF534040'));
		options.x = 1100;
		options.y = 640;
		add(options);

		optionsText.setFormat("assets/fonts/main.ttf", 32, FlxColor.WHITE);
		optionsText.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 8, 8);
		add(optionsText);

		mouseDistance.makeGraphic(0, 0, FlxColor.RED);
		add(mouseDistance);

		var version:FlxText = new FlxText(20, 680, 1920, 'You are running v${Main.luversion}');
		version.setFormat("assets/fonts/main.ttf", 20, Std.parseInt('0xFF4D4242'));
		version.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 8, 8);
		version.bold = true;
		version.underline = true;
		new FlxTimer().start(5, function(e) {
			FlxTween.tween(version, {y: 720, alpha: 0, "scale.y": 0.6}, 2, {ease: FlxEase.circIn, onComplete: function(e) {
				version.destroy();
			}});
		});
		add(version);

		if (Prefs.allowParticles) {
			new FlxTimer().start(Prefs.lowDetail ? 0.4 : 0.05, function(e) {
				var sprite:FlxSprite = new FlxSprite(FlxG.random.float(-16, 1296), 720);
				sprite.makeGraphic(16, 16, FlxColor.WHITE);
				sprite.alpha = 0.6;
				FlxTween.tween(sprite, {
					x: sprite.x + FlxG.random.float(-50, 50),
					y: sprite.y - FlxG.random.float(200, 250),
					alpha: 0,
					angle: FlxG.random.float(-90, 90)
				}, FlxG.random.float(1, 5), {onComplete: function(e) {
					sprite.destroy();
				}});
				add(sprite);
			}, 0);
		}

		var funny:FlxSprite = new FlxSprite().makeGraphic(1920, 1080, FlxColor.BLACK);
		FlxTween.tween(funny, {alpha: 0}, 0.5, {onComplete: function(e) {
			funny.destroy();
		}});
		add(funny);

		sleepy.makeGraphic(1920, 1080, FlxColor.BLACK);
		sleepy.alpha = 0;
		add(sleepy);
	}

	function generate() {
		for (table in spriteIDList) for (sprite in table) sprite.destroy();

		for (table in textIDList) for (text in table) text.destroy();

		function dumb(Value:Float):Void yPos = Value;

		disableMoving = true;
		FlxTween.num(yPos, 0, 0.6, {ease: FlxEase.backOut, onComplete: function(e) {
			disableMoving = false;
		}}, dumb);

		textIDList = [];
		textYPos = [];
		spriteIDList = [];
		spriteYPos = [];
		luaLists = [];

		var checks:Array<String> = FileSystem.readDirectory('mods/');
		var done:Int = 0;
		for (folder in checks) {
			var fileName:String = "mods/" + folder + "/";
			if (FileSystem.exists(fileName + "source/main.lua")) {
				var name:String = folder;
				var cred:String = "Unknown";
				var pngExist:Bool = FileSystem.exists(fileName + "pack.png");

				if (FileSystem.exists(fileName + "pack.json")) {
					try {
						var extract = Json.parse(File.getContent(fileName + "pack.json"));

						name = extract.name;
						cred = extract.author;
					} catch(e) trace('JSON for $folder is not formatted correctly.\nError: $e');
				}
				luaLists.push([name, fileName + "source/main.lua", folder, cred]);

				spriteIDList.push([]);
				var l:Int = spriteIDList.length-1;
				var sprID:Int = 0;
				for (i in 0...(Prefs.lowDetail ? 1 : 2)) {
					spriteIDList[l].push(new FlxSprite().makeGraphic(816 + (14 * i), 126 + (14 * i), (i == 0 ? Std.parseInt('0xFF454545') : Std.parseInt('0xFF777777'))));
					spriteIDList[l][i].screenCenter();
					spriteIDList[l][i].alpha = 0.25;
					spriteIDList[l][i].y = 70 + (160 * done) - (i == 1 ? 7 : 0);
					add(spriteIDList[l][i]);
					sprID++;
				}

				textIDList.push([]);
				textIDList[done].push(new FlxText(-255, 75 + (160 * done), 1280, name, 24));
				textIDList[done][0].setFormat("assets/fonts/main.ttf", 40, FlxColor.WHITE, RIGHT, OUTLINE, FlxColor.BLACK);
				add(textIDList[done][0]);

				textIDList[done].push(new FlxText(-255, 130 + (160 * done), 1280, cred, 24));
				textIDList[done][1].setFormat("assets/fonts/main.ttf", 40, FlxColor.WHITE, RIGHT, OUTLINE, FlxColor.BLACK);
				add(textIDList[done][1]);

				var image:BitmapData = null;
				if (pngExist) image = BitmapData.fromFile(fileName + "pack.png");

				spriteIDList[l].push(new FlxSprite().loadGraphic(pngExist ? image : "assets/images/unknown.png"));
				spriteIDList[l][sprID].y = 58 + (160 * done);
				spriteIDList[l][sprID].scale.x = 0.75;
				spriteIDList[l][sprID].scale.y = 0.75;
				spriteIDList[l][sprID].x = 230;
				add(spriteIDList[l][sprID]);

				done++;
			}
		}

		if (done == 0) {
			Application.current.window.alert("There is nothing installed, to prevent crashing your game, it will be closed", "Warning");
			lime.system.System.exit(1);
		}

		for (table in spriteIDList)
			for (sprite in table) spriteYPos.push(sprite.y);

		for (table in textIDList)
			for (text in table) textYPos.push(text.y);

		var text:FlxText = new FlxText(20, 20, 1920, 'Fetched $done app(s).', 16);
		text.setFormat("assets/fonts/main.ttf", 20, FlxColor.GREEN);
		text.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 8, 8);
		text.alpha = 0;
		FlxTween.tween(text, {alpha: 1, y: 20}, 1, {ease: FlxEase.circOut});
		new FlxTimer().start(3, function(e) {
			FlxTween.tween(text, {alpha: 0, y: 0}, 1, {ease: FlxEase.backOut, onComplete: function(e) {
				text.destroy();
			}});
		});
		add(text);

		choice = 0;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		for (sprite in members)
		{
			var sprite:Dynamic = sprite;
			var sprite:FlxSprite = sprite;
			if(sprite != null && (sprite is FlxSprite) && !(sprite is FlxText)) sprite.antialiasing = Prefs.antiAliasing;
		}

		if (!disableMoving) {
			choice = -1;
			var heldID:Int = 0;
			for (sprite in spriteIDList) {
				if (FlxG.mouse.overlaps(sprite[0])) {
					choice = heldID;
					oldChoice = choice;
					break;
				}
				heldID++;
			}
		}

		if (!disableMoving) {
			if (FlxG.mouse.justPressed) {
				mouseYPos = FlxG.mouse.y;
				oldYPos = yPos;
			}

			if (FlxG.mouse.pressed) {
				var y:Int = FlxG.mouse.y;
				yPos = oldYPos + (y - mouseYPos);
				if (tickLeft == 0) {
					tickLeft = 5;
					mouseScroll = (mouseDistance.y - y)/4;
					mouseDistance.y = y;
				}
				tickLeft--;
			} else if (mouseScroll != 0) {
				if (mouseScroll > 0) {
					yPos -= mouseScroll;
					mouseScroll -= 0.25;
				} else {
					yPos -= mouseScroll;
					mouseScroll += 0.25;
				}
			}

			if (yPos < -160 * (luaLists.length - 4)) yPos = -160 * (luaLists.length - 4);
			if (yPos > -5) yPos = -5;
		}

		var id:Int = 0;
		for (table in spriteIDList) {
			for (sprite in table) {
				sprite.y = spriteYPos[id] + yPos;
				id++;
			}
		}

		id = 0;
		for (table in textIDList) {
			for (text in table) {
				text.y = textYPos[id] + yPos;
				id++;
			}
		}

		var numChosen:Int = -1;
		for (tab in textIDList) {
			numChosen++;
			for (i in 0...2) textIDList[numChosen][i].color = numChosen == choice ? FlxColor.YELLOW : FlxColor.WHITE;
		}

		if (FlxG.mouse.justReleased && choice != -1 && !disableMoving) {
			disableMoving = true;
			var sprite:FlxSprite = new FlxSprite().makeGraphic(1920, 1080, FlxColor.BLACK);
			sprite.alpha = 0;
			FlxG.sound.music.fadeOut(0.5, 0);
			FlxTween.tween(sprite, {alpha: 1}, 1, {onComplete: function(e) {
				modName = luaLists[choice][2];
				modRaw = "mods/" + luaLists[choice][2] + "/";
				author = luaLists[choice][3];
				Main.changeWindowName(modName);
				lolArray.push(new LuaEngine(luaLists[choice][1]));
				FlxG.sound.destroy(true);
				FlxG.switchState(Dummy.new);
			}});
			add(sprite);

			var choose:Sound = Sound.fromFile('assets/sounds/choose.ogg');
			choose.play();
		}

		if (FlxG.mouse.overlaps(options)) {
			if (allowTween) {
				FlxTween.tween(optionsText, {alpha: 1}, 0.3);
				FlxTween.tween(optionsBG,   {alpha: 1}, 0.3);
				FlxTween.tween(options,     {alpha: 1}, 0.3);
				allowTween = false;
			}

			if (FlxG.mouse.justPressed) {
				var movement:FlxSprite = new FlxSprite().makeGraphic(1920, 1080, FlxColor.BLACK);
				movement.alpha = 0;
				FlxG.sound.music.fadeOut(0.5, 0);
				FlxTween.tween(movement, {alpha: 1}, 0.5, {onComplete: function(e) {
					FlxG.switchState(Options.new);
				}});
				add(movement);

				var choose:Sound = Sound.fromFile('assets/sounds/choose.ogg');
				choose.play();
			}
		} else {
			if (!allowTween) {
				FlxTween.tween(optionsText, {alpha: 0.5}, 0.3);
				FlxTween.tween(optionsBG,   {alpha: 0.5}, 0.3);
				FlxTween.tween(options,     {alpha: 0.5}, 0.3);
				allowTween = true;
			}
		}

		if (FlxG.mouse.justMoved) oldTime = Timer.stamp();

		FlxTween.globalManager.cancelTweensOf(sleepy);
		if (Timer.stamp() > oldTime + 30)
			FlxTween.tween(sleepy, {alpha: 0.66}, 2);
		else
			FlxTween.tween(sleepy, {alpha: 0},    0.25);

		if (FlxG.keys.justPressed.R) generate();
	}
}