package state;

class OptionsState extends FlxState {
	var options:Array<Array<Dynamic>> = [
		["LuApps Settings",  "Have too many LuApps but want to show to something else? Now you can set them here.", "State"],
		["Show Type",        "What type of LuApps you want it to show?",                                            "String", "luAppsType",      ["ALL"]],
		["Calculate Size",   "Whatever or not you want to calculate the size of an LuApp File.",                    "Bool",   "calculateSize"],

		["Graphics",         "Setting your graphic to whatever's beautiful or just plain toaster.",                 "State"],
		["Anti-Aliasing",    "If ON, most of the objects (especially images) will be sharped and clean.",           "Bool",   "antiAliasing"],
		["Low Detail",       "If ON, most details such as 2 overlapping objects on PlayState will be removed.",     "Bool",   "lowDetail"],
		["Framerate",        "How low or high do you want for the framerate?",                                      "Int",    "framerate",       [60, 240, 1, 7]], // Min, Max, Times per Change, Ticks per Change
		["Resolution",       "How little or much quality do you want? Will resize if it's changed.",                "String", "screenSize",      ["640x360", "1280x720", "1920x1080"]],
		["Shaders",          "If ON, shaders will be active. (Will cause stutters if it's a weak PC.)",             "Bool",   "shaders"],

		["Visuals",          "For the people who wants to disable something distracting or etc.",                   "State"],
		["Allow Particles.", "If ON, particles will be used. This will likely increase CPU loads.",                 "Bool",   "allowParticles"],
		["Show FPS",         "If ON, the FPS (with memory count) will be shown in the top left of this program.",   "Bool",   "showFPS"],
		["Notifications",    "If ON, notifications will be shown on the Application State",                         "Bool",   "notification"],
		["Discord RPC",      "If ON, Discord RPC will be enabled so other discord users can see what you play.",    "Bool",   "discordRPCAllow"],

		["Debugging",        "For Developers debugging their application or this program.",                         "State"],
		["Restart by [R]",   "If ON, pressing [R] will restart the LuApps. Only intended for developers!",          "Bool",   "restartByR"],
	];
	var requiresRestart:Array<String> = ["Discord RPC"];
	var rrEnabled:Bool = false;

	var helpText:UtilText = new UtilText(0, 0, 1280, "Use your mouse and hold left click and move up or down to scroll. Left click on an option to change it.\nPress BACKSPACE or ESCAPE to leave options.", 24, CENTER, SHADOW, null, FlxColor.YELLOW);
	var spriteList:Array<Array<FlxSprite>> = [];
	var spriteYPos:Array<Float> = [];
	var textList:Array<Array<UtilText>> = [];
	var textYPos:Array<Float> = [];
	var previewText:Array<Array<Dynamic>> = [];
	var heldText:UtilText = new UtilText(0, 0, 1280, "", 20, null, null, null, null, 'assets/fonts/settings.ttf');
	var mouseDistance:FlxSprite = new FlxSprite().makeGraphic(0, 0, FlxColor.RED);
	var optionGroup:FlxGroup = new FlxGroup();
	var jumpGroup:FlxGroup = new FlxGroup();

	var yPos:Float = 0;
	var maxYPos:Float = 0;
	var isSettingThing:Bool = false;
	var allowMoving:Bool = true;
	var triggered:Bool = false;
	var ticksRemain:Int = 0;
	var curOption:Int = 0;
	var heldProps:Array<Dynamic> = [false, 0, 0, new FlxSprite(), new FlxSprite()];
	var currentLDStatus:Bool = Prefs.lowDetail;

	override public function create() {
		Main.changeWindowName("Settings");
		DiscordRPC.changePresence("On Settings", "Setting some Changes.");
		rrEnabled = false;

		add(optionGroup);
		add(jumpGroup);

		var optionsBG:FlxSprite = new FlxSprite().makeGraphic(1280, 720, 0xFF756C6C);
		optionsBG.alpha = 0;
		FlxTween.tween(optionsBG, {alpha: 1}, 0.5);
		optionGroup.add(optionsBG);

		function sortLists(stringList:Array<String>):Array<String> {
			// Ai generated (sorry!)
			// Step 1: Count occurrences
			var map:Map<String, Int> = new Map();
			for (s in stringList) if (map.exists(s)) map.set(s, map.get(s) + 1); else map.set(s, 1);

			// Step 2: Format the result
			var returns:Array<String> = ["ALL"];
			for (key in map.keys()) returns.push('${key} [${map.get(key)}]');

			// Optional: Sort by count (descending)
			returns.sort(function(a, b) {
			    var aCount = Std.parseInt(a.split("[")[1].split("]")[0]);
			    var bCount = Std.parseInt(b.split("[")[1].split("]")[0]);
			    return bCount - aCount;
			});

			return returns;
		}

		// For LuApps Thingy
		options[1][4] = sortLists([for (thing in PlayState.luaLists) thing[4]]);

		var count:Int = 0;
		var yDown:Float = 0;
		var PTY:Int = -18;
		trace("Creating random things");
		for (option in options) {
			spriteList.push([]);
			textList.push([]);

			var i:Int = count;
			var j:Int = textList.length-1;
			var n:String = option[0];
			var t:String = option[2];

			var result:Float = yDown - 280;
			if (result < 0) result = 0;

			PTY += 16;
			if (t == "State") PTY += 13;
			previewText.push([result, new UtilText(10, PTY, n.length * 13.75, n, 13, LEFT, NONE, null, null, 'assets/fonts/debug.ttf')]);
			previewText[i][1].x += t != "State" ? 20 : 0;
			jumpGroup.add(previewText[i][1]);

			if (t != "State") {
				spriteList[i].push(new FlxSprite().makeGraphic(860, 105, 0xFF797979));
				spriteList[i][0].screenCenter();
				spriteList[i][0].y = 60 + yDown;
				optionGroup.add(spriteList[i][0]);

				if (!currentLDStatus) {
					spriteList[i].push(new FlxSprite().makeGraphic(845, 90, 0xFF363636));
					spriteList[i][1].screenCenter();
					spriteList[i][1].y = 67.5 + yDown;
					optionGroup.add(spriteList[i][1]);
				}

				textList[j].push(new UtilText(230, 75 + yDown, 1280, n, 56));
				textList[j][0].setBorderStyle(SHADOW, FlxColor.BLACK, PlayState.qSize, PlayState.qSize);
				optionGroup.add(textList[j][0]);

				var value:Dynamic = Reflect.getProperty(Prefs, option[3]);
				textList[j].push(new UtilText(-240, 88 + yDown - (currentLDStatus ? 6 : 0), 1280, '$value', 60, RIGHT, SHADOW));
				textList[j][1].setBorderStyle(SHADOW, FlxColor.BLACK, PlayState.qSize, PlayState.qSize);
				textList[j][1].underline = true;
				textList[j][1].font = 'assets/fonts/settings.ttf';
				optionGroup.add(textList[j][1]);

				if (option[2] == "Bool") textList[j][1].text = value ? "ON" : "OFF";

				yDown += 115;
			} else {
				textList[j].push(new UtilText(0, 90 + yDown, 1280, option[0], 64, CENTER, SHADOW));
				textList[j][0].setBorderStyle(SHADOW, FlxColor.BLACK, PlayState.qSize, PlayState.qSize);
				optionGroup.add(textList[j][0]);

				textList[j].push(new UtilText(0, 164 + yDown, 1280, option[1], 24, CENTER, null, null, 0xFF8D8D8D));
				textList[j][1].setBorderStyle(SHADOW, FlxColor.BLACK, PlayState.qSize, PlayState.qSize);
				optionGroup.add(textList[j][1]);

				yDown += 160;
			}

			count++;
		}

		maxYPos = -(yDown < 630 ? 0 : yDown - 630);

		helpText.setBorderStyle(SHADOW, FlxColor.BLACK, 8, 8);
		helpText.screenCenter();
		helpText.y = 650;
		jumpGroup.add(helpText);

		for (table in spriteList) for (sprite in table) spriteYPos.push(sprite.y);
		for (table in textList) for (text in table) textYPos.push(text.y);

		FlxG.sound.playMusic('assets/music/settings.ogg', 1, true);

		var blackFade:FlxSprite = new FlxSprite().makeGraphic(1280, 720, 0xFF000000);
		FlxTween.tween(blackFade, {alpha: 0}, 0.5, {onComplete: e -> blackFade.destroy()});
		add(blackFade);

		jumpGroup.add(heldProps[4]);
		jumpGroup.add(heldProps[3]);
		heldText.screenCenter();
		jumpGroup.add(heldText);

		heldProps[4].alpha = 0;
		heldProps[3].alpha = 0;
		heldText.alpha = 0;

		trace("Done making random things.");
	}

	var option:Int = 0;
	var tickLeft:Int = 5;
	var oldYPos:Float = 0;
	var mouseYPos:Float = 0;
	var mouseScroll:Float = 0;
	var colArray:Array<Int> = [0, 0];
	override public function update(elapsed:Float) {
		colArray[1] = -1;
		helpText.angle = Math.sin(Timer.stamp());

		if (!isSettingThing) {
			option = -1;

			if (allowMoving) {
				applyColsAndTexts();
				for (sprite in previewText) {
					colArray[1] += sprite[1].x == 22 ? 2 : 1;
					if (FlxG.mouse.overlaps(sprite[1]) && FlxG.mouse.justPressed) {
						allowMoving = false;
						mouseScroll = 0;
						colArray[0] = colArray[1];
						
						function move(Value:Float):Void yPos = Value;
						
						FlxTween.num(yPos, Math.abs(maxYPos) < sprite[0] ? maxYPos : -sprite[0], 0.7, {ease: FlxEase.backOut, onComplete: e -> allowMoving = true}, move);
					
						sprite[1].color = FlxColor.YELLOW;
						FlxTween.color(sprite[1], 0.7, sprite[1].color, FlxColor.WHITE);
					
						var sound:FlxSound = FlxG.sound.load('assets/sounds/woosh.ogg');
						sound.play();
					
						break;
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
					yPos -= mouseScroll;
					mouseScroll += mouseScroll > 0 ? -0.25 : 0.25;
				}
		
				if (yPos < maxYPos) yPos = maxYPos;
				if (yPos > -5) yPos = -5;
			} else applyColsAndTexts(false, colArray[0]);

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

			if (FlxG.mouse.justPressed && option != -1 && allowMoving) {
				isSettingThing = true;
				var t:String = options[option][2];
				if (t.toLowerCase() == "int") ticksRemain = options[option][4][2];

				var count:Int = 0;
				for (spr in spriteList) {
					if (count != option) for (i in 0...spr.length) FlxTween.tween(spr[i], {alpha: 0.33}, 0.25);
					count++;
				}

				count = 0;
				for (txt in textList) {
					if (count != option) for (i in 0...txt.length) FlxTween.tween(txt[i], {alpha: 0.33}, 0.25);
					count++;
				}

				FlxTween.tween(helpText, {"scale.y": 0}, 0.1, {ease: FlxEase.linear, onComplete: e -> {
					helpText.text = 'This is a ${options[option][2]} type.\n';

					switch(options[option][2]) {
						case 'Int':    helpText.text += "A/Q/LEFT to decrement, D/RIGHT to increment.";
						case 'Bool':   helpText.text += "Enter to Switch";
						case 'String': helpText.text += "A/Q/LEFT to switch left, D/RIGHT to switch right.";
							// TODO: Not choose index 0 but instead whatever the save chose to use.
							curOption = options[option][4].indexOf(Reflect.getProperty(Prefs, options[option][3]));
					}

					FlxTween.tween(helpText, {"scale.y": 1 / (currentLDStatus ? 1 : 2)}, 0.1, {ease: FlxEase.linear});

					heldProps[0] = false;
					FlxTween.tween(heldText, {alpha: 0}, 0.2);
					FlxTween.tween(heldProps[3], {alpha: 0}, 0.2);
					FlxTween.tween(heldProps[4], {alpha: 0}, 0.2);
				}});
			}

			if (FlxG.keys.anyJustPressed([BACKSPACE, ESCAPE])) {
				Prefs.saveSettings();
				allowMoving = true;

				var movement:FlxSprite = new FlxSprite().makeGraphic(1280, 720, FlxColor.BLACK);
				movement.alpha = 0;
				FlxG.sound.music.fadeOut(0.5, 0);
				FlxTween.tween(movement, {alpha: 1}, 0.5, {onComplete: e -> FlxG.switchState(PlayState.new)});
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
				if (count != option) for (i in 0...spr.length) FlxTween.tween(spr[i], {alpha: 1}, 0.25);
				count++;
			}

			count = 0;
			for (txt in textList) {
				if (count != option) for (i in 0...txt.length) FlxTween.tween(txt[i], {alpha: 1}, 0.25);
				count++;
			}

			FlxTween.tween(helpText, {"scale.y": 0}, 0.1, {ease: FlxEase.linear, onComplete: e -> {
				helpText.text = 'Use your mouse and hold left click and move up or down to scroll. Left click on an option to change it.\nPress BACKSPACE or ESCAPE to leave options.';
				FlxTween.tween(helpText, {"scale.y": 1 / (currentLDStatus ? 1 : 2)}, 0.1, {ease: FlxEase.linear});
			}});
		}

		var t:String = options[option][2].toLowerCase();
		var v:Dynamic = t != "string" ? Reflect.getProperty(Prefs, options[option][3]) : options[option][4][curOption];
		var r = 0;
		
		var oldText:String = textList[option][1].text;
		switch(t) {
			case 'int':
				var allow:Array<Int> = [for (i in 0...4) options[option][4][i]];

				ticksRemain--;
				if (ticksRemain == 0) {
					if (FlxG.keys.anyPressed([Q, A, LEFT])) r = -allow[2];
					else if (FlxG.keys.anyPressed([D, RIGHT])) r = allow[2];

					ticksRemain = allow[3];
				}

				v += r;

				if (v < allow[0]) v = allow[0];
				else if (v > allow[1]) v = allow[1];

			case 'bool': if (FlxG.keys.justPressed.ENTER) v = !v;

			case 'string':
				if (FlxG.keys.anyJustPressed([Q, A, LEFT])) curOption--;
				else if (FlxG.keys.anyJustPressed([D, RIGHT])) curOption++;
				
				if (curOption < 0) curOption = Math.round(options[option][4].length-1);
				else if (curOption > options[option][4].length-1) curOption = 0;

				v = options[option][4][curOption];
		}

		Reflect.setProperty(Prefs, options[option][3], v);
		textList[option][1].text = v;

		switch(options[option][0]) {
			case 'Framerate':
				FlxG.updateFramerate = v;
				FlxG.drawFramerate = v;

			case 'Show FPS': Main.fpsVar.visible = v;

			case 'Anti-Aliasing':
				for (sprite in members) {
					var sprite:Dynamic = sprite;
					var sprite:FlxSprite = sprite;
					if(sprite != null && sprite is FlxSprite && !(sprite is UtilText)) sprite.antialiasing = Prefs.antiAliasing;
				}

			case 'Resolution': Utils.setDefaultResolution();
		}

		if (t == 'bool') textList[option][1].text = v ? "ON" : "OFF";

		if (oldText != textList[option][1].text && Prefs.allowParticles) {
			if (requiresRestart.contains(options[option][0]) && !rrEnabled) {
				rrEnabled = true;

				var restartText:UtilText = new UtilText(0, 560, 1280, "You chose an option that requires a engine restart!", 28, CENTER, null, null, FlxColor.YELLOW);
				restartText.scale.y = 0;
				FlxTween.tween(restartText, {"scale.y": 1 / (currentLDStatus ? 1 : 2)}, 0.5, {ease: FlxEase.backOut});
				jumpGroup.add(restartText);
			}
			// TODO: Actually make the cool thing show up and not hide.
			var sprite:UtilText = textList[option][1];
			var oldPopup:UtilText = new UtilText(sprite.x, sprite.y, sprite.width / (currentLDStatus ? 2 : 1), oldText, 60, RIGHT, OUTLINE);
			oldPopup.setBorderStyle(SHADOW, FlxColor.BLACK, PlayState.qSize, PlayState.qSize);
			oldPopup.underline = true;
			oldPopup.font = 'assets/fonts/settings.ttf';
			FlxTween.tween(oldPopup, {
				x: FlxG.random.float(sprite.x - 75, sprite.x + 75),
				y: oldPopup.y + 240,
				angle: FlxG.random.float(-50, 50),
				alpha: 0
			}, 0.66, {ease: FlxEase.cubeOut, onComplete: e -> oldPopup.destroy()});
			optionGroup.add(oldPopup);
		}
	}

	function applyColsAndTexts(didChoose:Bool = true, chosen:Int = -1) {
		var hasChosen:Bool = false;
		if (didChoose) {
			for (sprite in spriteList) {
				chosen++;
				if (options[chosen][2] != "State") {
					if (FlxG.mouse.overlaps(sprite[0])) {
						hasChosen = true;
						option = chosen;
						break;
					}
				}
			}
		} else hasChosen = true;

		var numChosen:Int = -1;
		var held:Bool = false;
		for (_ in textList) {
			numChosen++;
			if (options[numChosen][2] != "State") for (i in 0...2) textList[numChosen][i].color = (numChosen == chosen && hasChosen) ? FlxColor.YELLOW : FlxColor.WHITE;
		}

		held = hasChosen;
		if (held && allowMoving) {
			if (heldText.alpha != 0) return;

			if (!heldProps[0]) heldProps[2] = Timer.stamp();
			heldProps[1] = Timer.stamp() - heldProps[2];

			if (heldProps[1] > 0.5) {
				heldText.text = options[chosen][1];
				heldProps[3].makeGraphic((heldText.text.length * 11) + 16, 30, FlxColor.WHITE);
				heldProps[4].makeGraphic((heldText.text.length * 11) + 24, 38, 0xFFADADAD);

				heldProps[3].x = FlxG.mouse.x + 4;
				heldProps[3].y = FlxG.mouse.y + 23;
				heldProps[4].x = FlxG.mouse.x;
				heldProps[4].y = FlxG.mouse.y + 19;
				heldText.x = FlxG.mouse.x + 10;
				heldText.y = FlxG.mouse.y + 29;

				FlxTween.tween(heldText, {alpha: 1}, 0.2);
				FlxTween.tween(heldProps[3], {alpha: 1}, 0.2);
				FlxTween.tween(heldProps[4], {alpha: 1}, 0.2);
			}
		} else {
			FlxTween.tween(heldText, {alpha: 0}, 0.2);
			FlxTween.tween(heldProps[3], {alpha: 0}, 0.2);
			FlxTween.tween(heldProps[4], {alpha: 0}, 0.2);
		}

		heldProps[0] = held;
	}
}