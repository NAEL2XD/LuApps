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
			"Framerate",
			"How low or high do you want for the framerate?",
			"Int",
			"framerate",
			[60, 240, 5, 1]
			// This is only for INT, 1st is Min, 2nd is Max, 3rd is ticks per frame till increment or decrement, 4th is how much they'll be incremented
		],
		[
			"Show FPS",
			"If ON, the FPS (with memory count) will be shown in the top left of this program.",
			"Bool",
			"showFPS"
		],
		[
			"Allow Particles.",
			"If ON, particles will be used. This will increase CPU loads.",
			"Bool",
			"allowParticles"
		]
	];

	var helpText:FlxText = new FlxText(0, 0, 1280, "Use your mouse and hover over an option and left click to select it\nPress BACKSPACE or ESCAPE to leave options.");

	var spriteList:Array<Array<FlxSprite>> = [];
	var spriteYPos:Array<Float> = [];
	var textList:Array<Array<FlxText>> = [];
	var textYPos:Array<Float> = [];
	var yPos:Float = 0;
	var isSettingThing:Bool = false;
	var allowMoving:Bool = true;
	var triggered:Bool = false;
	var oldTimer:Float = 0;
	var ticksRemain:Int = 0;

	override public function create()
	{
		var optionsBG:FlxSprite = new FlxSprite().makeGraphic(1280, 720, Std.parseInt('0xFF756C6C'));
		optionsBG.alpha = 0;
		FlxTween.tween(optionsBG, {alpha: 1}, 0.5);
		add(optionsBG);

		var count:Int = 0;
		for (option in options) {
			spriteList.push([]);
			textList.push([]);

			var i:Int = count;
			spriteList[i].push(new FlxSprite().makeGraphic(860, 130, Std.parseInt('0xFF797979')));
			spriteList[i][0].screenCenter();
			spriteList[i][0].y = 60 + (160 * i);
			add(spriteList[i][0]);

			spriteList[i].push(new FlxSprite().makeGraphic(845, 115, Std.parseInt('0xFF363636')));
			spriteList[i][1].screenCenter();
			spriteList[i][1].y = 67.5 + (160 * i);
			add(spriteList[i][1]);

			var n:String = option[0];
			var d:String = option[1];

			textList[i].push(new FlxText(230, 75 + (160 * i), 1280, n));
			textList[i][0].setFormat('assets/fonts/main.ttf', 56, FlxColor.WHITE);
			textList[i][0].setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 8, 8);
			add(textList[i][0]);

			textList[i].push(new FlxText(230, 145 + (160 * i), 1280, d));
			textList[i][1].setFormat('assets/fonts/main.ttf', 20, FlxColor.WHITE);
			textList[i][1].setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 8, 8);
			add(textList[i][1]);

			var value:Dynamic = Reflect.getProperty(Prefs, option[3]);
			textList[i].push(new FlxText(-240, 70 + (160 * i), 1280, '$value', 60));
			textList[i][2].setFormat('assets/fonts/main.ttf', 60, FlxColor.WHITE, RIGHT, OUTLINE, FlxColor.BLACK);
			textList[i][2].setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 8, 8);
			textList[i][2].underline = true;
			add(textList[i][2]);

			if (option[2] == "Bool") textList[i][2].text = value ? "ON" : "OFF";

			trace(value);

			count++;
		}

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
	override public function update(elapsed:Float)
	{
		if (!allowMoving) return;

		if (!isSettingThing) {
			option = -1;
			var chosen:Int = -1;
			for (sprite in spriteList) {
				chosen++;
				if (FlxG.mouse.overlaps(sprite[0])) {
					option = chosen;
					break;
				}
			}

			var numChosen:Int = -1;
			if (option != -1) {
				for (tab in textList) {
					numChosen++;
					for (i in 0...3) textList[numChosen][i].color = numChosen == chosen ? FlxColor.YELLOW : FlxColor.WHITE;
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
				helpText.text = 'Use your mouse and hover over an option and left click to select it\nPress BACKSPACE or ESCAPE to leave options.';
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

		switch(options[option][0]) {
			case 'Framerate':
				FlxG.updateFramerate = v;
				FlxG.drawFramerate = v;

			case 'Show FPS':
				Main.fpsVar.visible = v;
		}

		Reflect.setProperty(Prefs, options[option][3], v);
		textList[option][2].text = v;

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