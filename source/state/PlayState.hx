package state;

var luaLists:Array<Array<String>> = [];

class PlayState extends FlxState {
	public static var author:String;
	public static var modName:String;
	public static var modRaw:String;
	public static var appVersion:String;
	public static var qSize:Int = 8;

	var bgGroup:FlxGroup = new FlxGroup();
	var appGroup:FlxGroup = new FlxGroup();
	var utilGroup:FlxGroup = new FlxGroup();

	var spriteIDList:Array<Array<FlxSprite>> = [];
	var spriteYPos:Array<Float> = [];
	var spriteTrail:Array<FlxTrail> = [];
	var textIDList:Array<Array<UtilText>> = [];
	var textYPos:Array<Float> = [];

	var curNotifSpr:Array<Array<FlxSprite>> = [];
	var mouseDistance:FlxSprite = new FlxSprite();
	var optionsBG:FlxSprite = new FlxSprite().makeGraphic(165, 60, 0xFFA78080);
	var options:FlxSprite = new FlxSprite().makeGraphic(155, 50, 0xFF534040);
	var sleepy:FlxSprite = new FlxSprite().makeGraphic(1920, 1080, FlxColor.BLACK);

	var curNotifTxt:Array<Array<UtilText>>   = [];
	var optionsText:UtilText = new UtilText(1095, 642, 1920, "Options", 32);
	var noApps:UtilText = new UtilText(0, 0, 1280, "There are no applications installed!\nPress R to refresh the list.", 32, CENTER);

	var background:FlxBackdrop = new FlxBackdrop(FlxGridOverlay.createGrid(60, 60, 120, 120, true, 0xffa3a3a3, 0x0));
	var GMB:GlowingMarblingBlack = new GlowingMarblingBlack();
	var file:FileDialog = new FileDialog();

	var allowTween:Bool = false;
	var yPos:Float = -5;
	var maxYPos:Float = 0;
	var oldYPos:Float = 0;
	var mouseYPos:Float = 0;
	var mouseScroll:Float = 0;
	var wheelSpeed:Float = 0;
	var oldTime:Float = 0;
	var tickLeft:Int = 5;
	var choice:Int = 0;
	var disableMoving:Bool = false;
	var hasNoApps:Bool = false;
	var notifsSent:Int = 0;
	var notifsGone:Int = 0;
	
	override public function create() {
		Main.changeWindowName("Applications");
		if (!FileSystem.exists("mods/")) FileSystem.createDirectory("mods/");
		DiscordRPC.changePresence("Currently on Menu", "Browsing Apps");

		if (modRaw != "") {
			modRaw = "";
			if (FlxG.sound.music != null) FlxG.sound.music.stop();
		}
		
		FlxG.autoPause = false;
		if (!FlxG.fullscreen) Utils.setDefaultResolution();
		FlxG.sound.muted = false;
		FlxG.mouse.enabled = true;
		FlxG.mouse.visible = true;
		FlxG.sound.playMusic("assets/music/menu.ogg", 1, true);
		FlxG.camera.pixelPerfectRender = true;
		add(bgGroup);
		add(appGroup);
		add(utilGroup);
		
		oldTime = Timer.stamp();
		qSize = 8 * (Prefs.lowDetail ? 1 : 2);
		modName = "";

		var gray:FlxSprite = new FlxSprite().makeGraphic(1920, 1080, 0xFF222222);
		if (Prefs.shaders) gray.shader = GMB;
		bgGroup.add(gray);

		// From JS Engine.
		if (Prefs.allowParticles) {
			background.color = 0xff467172;
			background.alpha = 0.33;
			background.updateHitbox();
			bgGroup.add(background);
		}

		noApps.screenCenter();
		FlxTween.tween(noApps, {alpha: 0}, 1.5, {type: PINGPONG});
		noApps.visible = false;
		utilGroup.add(noApps);

		var gradSprite:FlxSprite = FlxGradient.createGradientFlxSprite(1280, 240, [0x00000000, 0xff000000], Prefs.lowDetail ? 16 : 1);
		gradSprite.y = 480;
		utilGroup.add(gradSprite);

		optionsBG.x = 1080;
		optionsBG.y = 635;
		utilGroup.add(optionsBG);

		options.x = 1085;
		options.y = 640;
		utilGroup.add(options);

		optionsText.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, qSize, qSize);
		utilGroup.add(optionsText);

		generate();

		var version:UtilText = new UtilText(20, 680, 1920, 'You are running v${Main.luversion}', 20, LEFT);
		version.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, qSize, qSize);
		version.color = 0xFF573C3C;
		version.bold = true;
		version.underline = true;
		new FlxTimer().start(5, e -> FlxTween.tween(version, {y: 720, alpha: 0, "scale.y": 0.6 / (Prefs.lowDetail ? 1 : 2)}, 2, {ease: FlxEase.circIn, onComplete: e -> version.destroy()}));
		utilGroup.add(version);

		if (Prefs.allowParticles) {
			new FlxTimer().start(Prefs.lowDetail ? 0.4 : 0.05, e -> {
				var sprite:FlxSprite = new FlxSprite(FlxG.random.float(-16, 1296), 720);
				sprite.makeGraphic(16, 16, FlxColor.WHITE);
				sprite.alpha = Math.abs(-0.6 + (sleepy.alpha / 1.9));
				FlxTween.tween(sprite, {
					x: sprite.x + FlxG.random.float(-50, 50),
					y: sprite.y - FlxG.random.float(200, 250),
					alpha: 0,
					angle: FlxG.random.float(-90, 90)
				}, FlxG.random.float(1, 5), {onComplete: e -> sprite.destroy()});
				bgGroup.add(sprite);
			}, 0);
		}

		var tip:Array<String> = [
			"Pressing \"I\" will allow you to import .luapp file!",
			"Did you know that it's open source?",
			"LUAPI Documentation are from the GitHub!",
			"You can also scroll with the mouse cursor!",
			"Get a Auto Completer, increase the speed of programming!",
			"It took 1 month to make this.",
			"The logo is made by SyncGit12!"
		];
		sendNotification(tip[FlxG.random.int(0, tip.length-1)]);
		sendNotification("This is on a alpha state, changes will be made.");
		
		var funny:FlxSprite = new FlxSprite().makeGraphic(1920, 1080, FlxColor.BLACK);
		FlxTween.tween(funny, {alpha: 0}, 0.5, {onComplete: e -> funny.destroy()});
		add(funny);

		file.onSelect.add(file -> {
			var error:Bool = false;
			var temp:String = "mods/temp/";
			trace(FileSystem.exists(temp));
			function del() if (FileSystem.exists(temp)) deleteDirectoryRecursive(temp);

			if (!file.endsWith('.luapp')) {
				sendNotification("Not a .luapp compressed file!");
				return;
			}

			try {
				var entries = Reader.readZip(new BytesInput(File.getBytes(file)));
				var folderName:String = "";
				var luappName:String = "";
				var first:Bool = true;
				if (!FileSystem.exists(temp)) FileSystem.createDirectory(temp);

				for (file in entries) {
					if (first) {
						folderName = file.fileName;
						first = false;
						luappName = file.fileName.substr(0, file.fileName.length-1);
						if (FileSystem.exists('mods/$folderName')) {
							sendNotification('$luappName already exists!');
							error = true;
							del();
							return;
						}
					}
					if (file.fileName.endsWith("/")) FileSystem.createDirectory('${temp}${file.fileName}'); else File.saveBytes('${temp}${file.fileName}', file.data);
				}

				var path:String = '${temp}${folderName}';
				if (FileSystem.exists('${path}source/main.lua')) {
					try Json.parse(File.getContent('${path}pack.json')) catch(e) {
						sendNotification('pack.json is invalid, cannot install.');
						error = true;
						del();
						return;
					}

					FileSystem.rename(path, 'mods/$folderName');
					generate(false);
					sendNotification('Successfully installed $luappName!');
				} else sendNotification('source/main.lua not found, cannot install.');
				del();
			} catch(e) {
				if (!error) sendNotification('Unknown Error!\n$e');
				del();
			};
		});

		super.create();
	}

	function generate(send:Bool = true) {
		for (table in spriteIDList) for (sprite in table) sprite.destroy();
		for (table in textIDList) for (text in table) text.destroy();
		for (table in spriteTrail) table.destroy();

		function dumb(Value:Float):Void yPos = Value;

		disableMoving = true;
		FlxTween.num(yPos, 0, 0.6, {ease: FlxEase.backOut, onComplete: e -> disableMoving = false}, dumb);

		textIDList = [];
		textYPos = [];
		spriteIDList = [];
		spriteYPos = [];
		spriteTrail = [];
		luaLists = [];

		var checks:Array<String> = FileSystem.readDirectory('mods/');
		var done:Int = 0;
		for (folder in checks) {
			var fileName:String = 'mods/$folder/';
			if (FileSystem.exists('${fileName}source/main.lua')) {
				var name:String = folder;
				var cred:String = "Unknown";
				var type:String = "ALL";
				var ver:String = "";
				var pngExist:Bool = FileSystem.exists('${fileName}pack.png');
				var gradient:Array<String> = ["0xFF292929", "0xFFCCCCCC", "0x24FFFFFF"];

				if (FileSystem.exists('${fileName}pack.json')) {
					try {
						var extract = Json.parse(File.getContent('${fileName}pack.json'));
						var skip:Bool = false;

						name     = extract.name;
						cred     = extract.author;
						type     = extract.appType;
						ver      = extract.version;
						if (extract.gradient != null) gradient = extract.gradient;
						for (hex in gradient) {
							if (hex.toLowerCase().startsWith("0x") && gradient.length == 3 && hex.length == 10) continue; else {
								sendNotification('$name\'s gradient JSON is not correct.');
								skip = true;
							}
						}

						if(skip) continue;
					} catch(e) sendNotification('$folder: $e');
				}

				if (ver == null) ver = "Unknown";
				if ((!Prefs.luAppsType.startsWith(type) && Prefs.luAppsType != "ALL") && File.getContent('${fileName}source/main.lua').length != 0) continue;
				else luaLists.push([name, '${fileName}source/main.lua', folder, cred, type, ver]);

				spriteIDList.push([]);
				var l:Int = spriteIDList.length-1;
				var sprID:Int = 0;
				for (i in 0...(Prefs.lowDetail ? 1 : 2)) {
					spriteIDList[l].push(FlxGradient.createGradientFlxSprite(816 + (14 * i), 126 + (14 * i), [Std.parseInt(gradient[2]), Std.parseInt(gradient[i])], Prefs.lowDetail ? 16 : 1));

					if (i == 1 && Prefs.allowParticles) {
						spriteTrail.push(new FlxTrail(spriteIDList[l][i], null, Prefs.lowDetail ? 8 : 32, 0, 0.09, 0.005));
						appGroup.add(spriteTrail[l]);
					}

					spriteIDList[l][i].screenCenter();
					spriteIDList[l][i].alpha = 0.2;
					spriteIDList[l][i].y = 70 + (160 * done) - (i == 1 ? 7 : 0);
					appGroup.add(spriteIDList[l][i]);
					sprID++;
				}

				textIDList.push([]);
				textIDList[done].push(new UtilText(-245, 75 + (160 * done), 1280, name, 40, RIGHT));
				appGroup.add(textIDList[done][0]);

				textIDList[done].push(new UtilText(-245, 118 + (160 * done), 1280, cred, 32, RIGHT));
				appGroup.add(textIDList[done][1]);

				textIDList[done].push(new UtilText(-245, 155 + (160 * done), 1280, '$ver' + (Prefs.calculateSize ? ' - ${FlxStringUtil.formatBytes(Utils.getDirectorySize(fileName))}' : ''), 22, RIGHT));
				textIDList[done][2].underline = true;
				appGroup.add(textIDList[done][2]);

				var image:BitmapData = null;
				if (pngExist) image = BitmapData.fromFile('${fileName}pack.png');

				spriteIDList[l].push(new FlxSprite().loadGraphic(pngExist ? image : "assets/images/unknown.png"));
				spriteIDList[l][sprID].scale.x = 0.75;
				spriteIDList[l][sprID].scale.y = 0.75;
				spriteIDList[l][sprID].x = 230;
				spriteIDList[l][sprID].y = 58 + (160 * done);
				appGroup.add(spriteIDList[l][sprID]);

				done++;
			}
		}

		maxYPos = 0;
		if (done >= 4) maxYPos = (-160 * (done - 4)) - 20;

		hasNoApps = done == 0;
		noApps.visible = done == 0;

		for (table in spriteIDList) for (sprite in table) spriteYPos.push(sprite.y);
		for (table in textIDList) for (text in table) textYPos.push(text.y);

		if (send) sendNotification('Fetched $done app(s).');
		/*var text:FlxText = new FlxText(20, 20, 1920, 'Fetched $done app(s).', 16);
		text.setFormat("assets/fonts/main.ttf", 20, FlxColor.GREEN);
		text.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 8, 8);
		text.alpha = 0;
		FlxTween.tween(text, {alpha: 1, y: 20}, 1, {ease: FlxEase.circOut});
		new FlxTimer().start(3, e -> FlxTween.tween(text, {alpha: 0, y: 0}, 1, {ease: FlxEase.backOut, onComplete: e -> text.destroy()}));
		add(text);*/

		sleepy.alpha = 0;
		add(sleepy);

		choice = 0;
	}

	override public function update(elapsed:Float) {
		if (Prefs.shaders) GMB.update(elapsed);

		if (Math.abs(wheelSpeed) > .0001) wheelSpeed = wheelSpeed/(1 + (0.2 / (Prefs.framerate / 60)));

		for (sprite in members) {
			var sprite:Dynamic = sprite;
			var sprite:FlxSprite = sprite;
			if(sprite != null && (sprite is FlxSprite) && !(sprite is UtilText)) sprite.antialiasing = Prefs.antiAliasing;
		}

		if (!disableMoving && maxYPos != 0) {
			if (FlxG.mouse.justPressed || FlxG.mouse.wheel != 0) {
				mouseYPos = FlxG.mouse.y;
				oldYPos = yPos;
			}

			if (FlxG.mouse.pressed || FlxG.mouse.wheel != 0) {
				var y:Int = FlxG.mouse.y;
				wheelSpeed += FlxG.mouse.wheel * 10;
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
			yPos += wheelSpeed;

			var hit:Bool = false;
			if (yPos < maxYPos) {
				yPos = maxYPos;
				hit = true;
			} else if (yPos > -5) {
				yPos = -5;
				hit = true;
			}
			
			if (hit) {
				mouseScroll = 0;
				wheelSpeed = 0;
			}
		}

		if (!hasNoApps) {
			if (!disableMoving) {
				choice = -1;
				var heldID:Int = 0;
				for (sprite in spriteIDList) {
					if (FlxG.mouse.overlaps(sprite[0])) {
						choice = heldID;
						break;
					}
					heldID++;
				}
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

			if(Math.abs(mouseScroll + wheelSpeed) < 1) {
				var numChosen:Int = -1;
				for (tab in textIDList) {
					numChosen++;
					for (i in 0...3) tab[i].color = numChosen == choice ? FlxColor.YELLOW : FlxColor.WHITE;
				}
			
				if (FlxG.mouse.justReleased && choice != -1 && !disableMoving) {
					disableMoving = true;
					FlxG.sound.music.fadeOut(0.5, 0);
					mouseScroll = 0;
					wheelSpeed = 0;
				
					var sprite:FlxSprite = new FlxSprite().makeGraphic(1920, 1080, FlxColor.BLACK);
					sprite.alpha = 0;
					FlxTween.tween(sprite, {alpha: 1}, 1, {onComplete: e -> {
						modName = luaLists[choice][0];
						modRaw = 'mods/${luaLists[choice][2]}/';
						author = luaLists[choice][3];
						appVersion = luaLists[choice][5];
						Dummy.luaArray.push(new LuaEngine(luaLists[choice][1]));
						Main.changeWindowName('$modName - $author');
						FlxG.sound.destroy(true);
						FlxG.switchState(Dummy.new);
					}});
					add(sprite);
				
					var choose:Sound = Sound.fromFile('assets/sounds/choose.ogg');
					choose.play();
				}
			}
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
				FlxTween.tween(movement, {alpha: 1}, 0.5, {onComplete: e -> FlxG.switchState(OptionsState.new)});
				add(movement);

				var choose:Sound = Sound.fromFile('assets/sounds/choose.ogg');
				choose.play();
			}
		} else if (!allowTween) {
			FlxTween.tween(optionsText, {alpha: 0.5}, 0.3);
			FlxTween.tween(optionsBG,   {alpha: 0.5}, 0.3);
			FlxTween.tween(options,     {alpha: 0.5}, 0.3);
			allowTween = true;
		}

		if (FlxG.mouse.justMoved || FlxG.keys.justPressed.ANY) oldTime = Timer.stamp();

		FlxTween.globalManager.cancelTweensOf(sleepy);
		if (Timer.stamp() > oldTime + 30) FlxTween.tween(sleepy, {alpha: 0.66}, 2); else FlxTween.tween(sleepy, {alpha: 0}, 0.25);

		if (FlxG.keys.justPressed.R) generate();

		if (FlxG.keys.justPressed.I) file.browse(FileDialogType.OPEN, "luapp", null, "LuApplication Path.");

		background.x += 0.45 / (Prefs.framerate / 60);
		background.y += (0.45 / (Prefs.framerate / 60)) - ((mouseScroll + -wheelSpeed)/2);

		super.update(elapsed);
	}

	function sendNotification(title:String) {
		if (!Prefs.notification) return;

		var l:Int = curNotifTxt.length;
		curNotifSpr.push([new FlxSprite(1276, 636 - (88 * notifsSent)).makeGraphic(303, 76, 0xff7e7e7e)]);
		curNotifSpr[l][0].alpha = 0;
		FlxTween.tween(curNotifSpr[l][0], {alpha: 1, x: 956}, 2, {ease: FlxEase.elasticOut});
		utilGroup.add(curNotifSpr[l][0]);

		if (!Prefs.lowDetail) {
			curNotifSpr[l].push(new FlxSprite(1280, 640 - (88 * notifsSent)).makeGraphic(295, 68, 0xff585858));
			curNotifSpr[l][1].alpha = 0;
			FlxTween.tween(curNotifSpr[l][1], {alpha: 1, x: 960}, 2, {ease: FlxEase.elasticOut});
			utilGroup.add(curNotifSpr[l][1]);
	
			/*curNotifSpr[l].push(new FlxSprite(1276, 708 - (88 * notifsSent)).makeGraphic(303, 4, 0xff000000));
			curNotifSpr[l][2].alpha = 0;
			FlxTween.tween(curNotifSpr[l][2], {alpha: 1, x: 956}, 2, {ease: FlxEase.elasticOut});
			utilGroup.add(curNotifSpr[l][2]);*/
			// no idea how i'm suppose to do this
		}

		curNotifTxt.push([new UtilText(1290, 648 - (88 * notifsSent), 275, title, 16)]);
		curNotifTxt[l][0].setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, qSize, qSize);
		curNotifTxt[l][0].alpha = 0;
		FlxTween.tween(curNotifTxt[l][0], {alpha: 1, x: 970}, 2, {ease: FlxEase.elasticOut});
		utilGroup.add(curNotifTxt[l][0]);

		new FlxTimer().start(5, {e -> {
			for (i in 0...curNotifSpr[l].length) FlxTween.tween(curNotifSpr[l][i], {alpha: 0}, 0.5, {onComplete: e -> curNotifSpr[l][i].destroy()});
			FlxTween.tween(curNotifTxt[l][0], {alpha: 0}, 0.5, {onComplete: e -> {
				curNotifTxt[l][0].destroy();
				notifsGone++;
				notifsSent--;

				// TODO: Try to not make the sprite go to another floor or smth??
				var nums:Array<Int> = [636, 640, 648];
				for (i in 0...curNotifSpr.length) {
					for (j in 0...curNotifSpr[i].length) FlxTween.tween(curNotifSpr[i][j], {y: nums[j] - (88 * (i - notifsGone))}, .66, {ease: FlxEase.backOut});
					FlxTween.tween(curNotifTxt[i][0], {y: nums[2] - (88 * (i - notifsGone))}, .66, {ease: FlxEase.backOut});
				}
			}});
		}});

		notifsSent++;
	}

	function deleteDirectoryRecursive(path:String):Void {
		if (!FileSystem.exists(path)) return;
	
		for (file in FileSystem.readDirectory(path)) {
			var full = '$path/$file';
			if (FileSystem.isDirectory(full)) deleteDirectoryRecursive(full); else try FileSystem.deleteFile(full) catch(e) sendNotification('Failed to delete file $full: $e');
		}
	
		try FileSystem.deleteDirectory(path) catch(e) sendNotification('Directory cannot be deleted.\n$e');
	}
}