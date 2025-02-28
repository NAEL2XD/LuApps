package;

import haxe.Timer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.FlxState;
import Prefs;

class Options extends FlxState
{
	var options:Array<Array<Dynamic>> = [
		[
			"Graphics",
			"Setting your graphic to whatever's beautiful or just plain toaster.",
			"State"
		],
		[
			"Anti-Aliasing",
			"If ON, most of the objects (especially images) will be sharped and clean.",
			"Bool",
			"antiAliasing"
		],
		[
			"Low Detail",
			"If ON, most details such as 2 overlapping objects on PlayState will be removed.",
			"Bool",
			"lowDetail"
		],
		[
			"Framerate",
			"How low or high do you want for the framerate?",
			"Int",
			"framerate",
			[60, 240, 3, 1]
			// This is only for INT, 1st is Min, 2nd is Max, 3rd is ticks per frame till increment or decrement, 4th is how much they'll be incremented
		],
		[
			"Visuals",
			"For the people who wants to disable something distracting or etc.",
			"State"
		],
		[
			"Allow Particles.",
			"If ON, particles will be used. This will likely increase CPU loads.",
			"Bool",
			"allowParticles"
		],
		[
			"Show FPS",
			"If ON, the FPS (with memory count) will be shown in the top left of this program.",
			"Bool",
			"showFPS"
		],
	];

	var helpText:FlxText = new FlxText(0, 0, 1280, "Use your mouse and hold left click and move up or down to scroll. Left click on an option to change it.\nPress BACKSPACE or ESCAPE to leave options.");

	var spriteList:Array<Array<FlxSprite>> = [];
	var spriteYPos:Array<Float> = [];
	var textList:Array<Array<FlxText>> = [];
	var textYPos:Array<Float> = [];

	var yPos:Float = 0;
	var maxYPos:Float = 0;
	var isSettingThing:Bool = false;
	var allowMoving:Bool = true;
	var triggered:Bool = false;
	var oldTimer:Float = 0;
	var ticksRemain:Int = 0;

	var mouseDistance:FlxSprite = new FlxSprite();

	override public function create()
	{
		Main.changeWindowName("Settings");

		mouseDistance.makeGraphic(0, 0, FlxColor.RED);
		add(mouseDistance);

		var optionsBG:FlxSprite = new FlxSprite().makeGraphic(1280, 720, Std.parseInt('0xFF756C6C'));
		optionsBG.alpha = 0;
		FlxTween.tween(optionsBG, {alpha: 1}, 0.5);
		add(optionsBG);

		var count:Int = 0;
		var yDown:Float = 0;
		for (option in options) {
			spriteList.push([]);
			textList.push([]);

			var j:Int = textList.length-1;

			var n:String = option[0];
			var d:String = option[1];
			var t:String = option[2];

			if (t != "State") {
				var i:Int = count;

				spriteList[i].push(new FlxSprite().makeGraphic(860, 130, Std.parseInt('0xFF797979')));
				spriteList[i][0].screenCenter();
				spriteList[i][0].y = 60 + yDown;
				add(spriteList[i][0]);

				spriteList[i].push(new FlxSprite().makeGraphic(845, 115, Std.parseInt('0xFF363636')));
				spriteList[i][1].screenCenter();
				spriteList[i][1].y = 67.5 + yDown;
				add(spriteList[i][1]);

				textList[j].push(new FlxText(230, 75 + yDown, 1280, n));
				textList[j][0].setFormat('assets/fonts/main.ttf', 56, FlxColor.WHITE);
				textList[j][0].setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 8, 8);
				add(textList[j][0]);

				textList[j].push(new FlxText(230, 145 + yDown, 1280, d));
				textList[j][1].setFormat('assets/fonts/main.ttf', 20, FlxColor.WHITE);
				textList[j][1].setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 8, 8);
				add(textList[j][1]);

				var value:Dynamic = Reflect.getProperty(Prefs, option[3]);
				textList[j].push(new FlxText(-240, 70 + yDown, 1280, '$value', 60));
				textList[j][2].setFormat('assets/fonts/main.ttf', 60, FlxColor.WHITE, RIGHT, OUTLINE, FlxColor.BLACK);
				textList[j][2].setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 8, 8);
				textList[j][2].underline = true;
				add(textList[j][2]);

				if (option[2] == "Bool") textList[j][2].text = value ? "ON" : "OFF";

				yDown += 160;
			} else {
				textList[j].push(new FlxText(0, 90 + yDown, 1280, option[0]));
				textList[j][0].setFormat('assets/fonts/main.ttf', 64, FlxColor.WHITE, FlxTextAlign.CENTER);
				textList[j][0].setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 8, 8);
				add(textList[j][0]);

				textList[j].push(new FlxText(0, 164 + yDown, 1280, option[1]));
				textList[j][1].setFormat('assets/fonts/main.ttf', 24, FlxColor.GRAY, FlxTextAlign.CENTER);
				textList[j][1].setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 8, 8);
				add(textList[j][1]);

				yDown += 160;
			}

			count++;
		}

		maxYPos = -(yDown < 630 ? 0 : yDown - 630);

		helpText.setFormat('assets/fonts/main.ttf', 24, FlxColor.YELLOW, CENTER);
		helpText.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 8, 8);
		helpText.screenCenter();
		helpText.y = 650;
		add(helpText);

		for (table in spriteList)
			for (sprite in table) spriteYPos.push(sprite.y);

		for (table in textList)
			for (text in table) textYPos.push(text.y);

		FlxG.sound.playMusic('assets/music/settings.ogg', 1, true);

		var blackFade:FlxSprite = new FlxSprite().makeGraphic(1280, 720, Std.parseInt('0xFF000000'));
		FlxTween.tween(blackFade, {alpha: 0}, 0.5, {onComplete: function(e) {
			blackFade.destroy();
		}});
		add(blackFade);
	}

	var option:Int = 0;
	var tickLeft:Int = 5;
	var oldYPos:Float = 0;
	var mouseYPos:Float = 0;
	var mouseScroll:Float = 0;
	override public function update(elapsed:Float)
	{
		if (!allowMoving) return;

		if (!isSettingThing) {
			option = -1;
			var chosen:Int = -1;
			for (sprite in spriteList) {
				chosen++;
				if (options[chosen][2] != "State") {
					if (FlxG.mouse.overlaps(sprite[0])) {
						option = chosen;
						break;
					}
				}
			}

			var numChosen:Int = -1;
			if (option != -1) {
				for (tab in textList) {
					numChosen++;
					if (options[numChosen][2] != "State")
						for (i in 0...3) textList[numChosen][i].color = numChosen == chosen ? FlxColor.YELLOW : FlxColor.WHITE;
				}
			}

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

			if (yPos < maxYPos) yPos = maxYPos;
			if (yPos > -5) yPos = -5;

			var id:Int = 0;
			for (table in spriteList) {
				for (sprite in table) {
					sprite.y = spriteYPos[id] + (yPos - 50);
					id++;
				}
			}

			id = 0;
			for (table in textList) {
				for (text in table) {
					text.y = textYPos[id] + (yPos - 50);
					id++;
				}
			}

			if (FlxG.mouse.justPressed && option != -1) {
				isSettingThing = true;
				var t:String = options[option][2];
				if (t.toLowerCase() != "bool") ticksRemain = options[option][4][2];

				var count:Int = 0;
				for (spr in spriteList) {
					if (count != option) {
						for (i in 0...spr.length)
							FlxTween.tween(spr[i], {alpha: 0.33}, 0.25);
					}
					count++;
				}

				count = 0;
				for (txt in textList) {
					if (count != option) {
						for (i in 0...txt.length)
							FlxTween.tween(txt[i], {alpha: 0.33}, 0.25);
					}
					count++;
				}

				FlxTween.tween(helpText, {"scale.y": 0}, 0.1, {ease: FlxEase.linear, onComplete: function(e) {
					helpText.text = 'This is a ${options[option][2]} type.\n';

					switch(options[option][2]) {
						case 'Int':  helpText.text  += "A/Q/LEFT to decrement, D/RIGHT to increment.";
						case 'Bool': helpText.text += "Enter to Switch";
					}

					FlxTween.tween(helpText, {"scale.y": 1}, 0.1, {ease: FlxEase.linear});
				}});
			}

			if (FlxG.keys.anyJustPressed([BACKSPACE, ESCAPE])) {
				Prefs.saveSettings();
				allowMoving = true;

				var movement:FlxSprite = new FlxSprite().makeGraphic(1280, 720, FlxColor.BLACK);
				movement.alpha = 0;
				FlxG.sound.music.fadeOut(0.5, 0);
				FlxTween.tween(movement, {alpha: 1}, 0.5, {onComplete: function(e) {
					FlxG.switchState(PlayState.new);
				}});
				add(movement);
			}

			return;
		}

		if (FlxG.keys.anyJustPressed([BACKSPACE, ESCAPE])) {
			isSettingThing = false;
			triggered = false;
			mouseScroll = 0; // I find it annoying, so i would do this.

			var count:Int = 0;
			for (spr in spriteList) {
				if (count != option) {
					for (i in 0...spr.length)
						FlxTween.tween(spr[i], {alpha: 1}, 0.25);
				}
				count++;
			}

			count = 0;
			for (txt in textList) {
				if (count != option) {
					for (i in 0...txt.length)
						FlxTween.tween(txt[i], {alpha: 1}, 0.25);
				}
				count++;
			}

			FlxTween.tween(helpText, {"scale.y": 0}, 0.1, {ease: FlxEase.linear, onComplete: function(e) {
				helpText.text = 'Use your mouse and hold left click and move up or down to scroll. Left click on an option to change it.\nPress BACKSPACE or ESCAPE to leave options.';
				FlxTween.tween(helpText, {"scale.y": 1}, 0.1, {ease: FlxEase.linear});
			}});
			
		}

		var t:String = options[option][2];
		var v:Dynamic = Reflect.getProperty(Prefs, options[option][3]);
		var r = 0;
		
		t = t.toLowerCase();
		var oldText:String = textList[option][2].text;
		switch(t) {
			case 'int' | 'float':
				var allow:Array<Int> = [for (i in 0...4) options[option][4][i]];

				ticksRemain--;
				if (ticksRemain == 0) {
					if (FlxG.keys.anyPressed([Q, A, LEFT])) r = -allow[3];
					else if (FlxG.keys.anyPressed([D, RIGHT])) r = allow[3];

					ticksRemain = allow[2];
				}

				v += r;

				if (v < allow[0]) v = allow[0];
				else if (v > allow[1]) v = allow[1];

			case 'bool': if (FlxG.keys.justPressed.ENTER) v = !v;
		}

		Reflect.setProperty(Prefs, options[option][3], v);
		textList[option][2].text = v;

		switch(options[option][0]) {
			case 'Framerate':
				FlxG.updateFramerate = v;
				FlxG.drawFramerate = v;

			case 'Show FPS':
				Main.fpsVar.visible = v;

			case 'Anti-Aliasing':
				for (sprite in members)
				{
					var sprite:Dynamic = sprite;
					var sprite:FlxSprite = sprite;
					if(sprite != null && (sprite is FlxSprite) && !(sprite is FlxText)) sprite.antialiasing = Prefs.antiAliasing;
				}
		}

		if (t == 'bool') textList[option][2].text = v ? "ON" : "OFF";

		if (oldText != textList[option][2].text && Prefs.allowParticles) {
			var sprite:FlxText = textList[option][2];
			var oldPopup:FlxText = new FlxText(sprite.x, sprite.y, sprite.width, oldText);
			oldPopup.setFormat('assets/fonts/main.ttf', 60, FlxColor.WHITE, RIGHT, OUTLINE, FlxColor.BLACK);
			oldPopup.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 8, 8);
			oldPopup.underline = true;
			FlxTween.tween(oldPopup, {
				x: FlxG.random.float(sprite.x - 75, sprite.x + 75),
				y: oldPopup.y + 240,
				angle: FlxG.random.float(-50, 50),
				alpha: 0
			}, 0.66, {ease: FlxEase.cubeOut, onComplete: function(e) {
				oldPopup.destroy();
			}});
			add(oldPopup);
		}
	}
}