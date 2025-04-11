package state;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
#if sys
import sys.FileSystem;
import sys.io.File;
#end
#if VIDEOS_ALLOWED
import backend.VideoSprite;
#end

class StartupState extends FlxState {
	var logo:FlxSprite;
	var skipTxt:FlxText;

	var theIntro:Int = FlxG.random.int(0, 0);

	public static var instance:StartupState;

	public var vidSprite:VideoSprite = null;

	public function startVideo(name:String, ?library:String = null, ?callback:Void->Void = null, canSkip:Bool = true, loop:Bool = false,
			playOnLoad:Bool = true) {
		#if VIDEOS_ALLOWED
		var foundFile:Bool = false;
		var fileName:String = "assets/videos/" + name + ".mp4";

		#if sys
		if (FileSystem.exists(fileName))
		#else
		if (OpenFlAssets.exists(fileName))
		#end
		foundFile = true;

		if (foundFile) {
			vidSprite = new VideoSprite(fileName, false, canSkip, loop);

			// Finish callback
			function onVideoEnd()
				FlxG.switchState(state.PlayState.new);
			vidSprite.finishCallback = (callback != null) ? callback.bind() : onVideoEnd;
			vidSprite.onSkip = (callback != null) ? callback.bind() : onVideoEnd;
			insert(0, vidSprite);

			if (playOnLoad)
				vidSprite.videoSprite.play();
			return vidSprite;
		} else {
			FlxG.log.error("Video not found: " + fileName);
			new FlxTimer().start(0.1, function(tmr:FlxTimer) {
				FlxG.switchState(state.PlayState.new);
			});
		}
		#else
		FlxG.log.warn('Platform not supported!');
		#end
		return null;
	}

	override function create() {
		Main.changeWindowName("Startup");
		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;
		skipTxt = new FlxText(0, FlxG.height, 0, 'Press ENTER To Skip', 16);
		skipTxt.setFormat('assets/fonts/debug.ttf', 14, FlxColor.WHITE);
		skipTxt.borderSize = 1.5;
		skipTxt.antialiasing = true;
		skipTxt.scrollFactor.set();
		skipTxt.alpha = 0;
		skipTxt.y -= skipTxt.textField.textHeight;
		add(skipTxt);

		FlxTween.tween(skipTxt, {alpha: 1}, 1);

		new FlxTimer().start(0.1, function(tmr:FlxTimer) {
			switch (theIntro) {
				case 0:
					#if VIDEOS_ALLOWED
					startVideo('luAppsIntro');
					#else
					trace('Videos are not allowed, skipping');
					#end
			}
		});

		super.create();
	}

	function onIntroDone() {
		FlxTween.tween(logo, {alpha: 0}, 1, {
			ease: FlxEase.linear,
			onComplete: function(_) {
				FlxG.switchState(state.PlayState.new);
			}
		});
	}

	override function update(elapsed:Float) {
		if (FlxG.keys.justPressed.ENTER)
			FlxG.switchState(state.PlayState.new);

		super.update(elapsed);
	}
}
