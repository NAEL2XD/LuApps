package utils;

class Utils {
	public static function setDefaultResolution() {
		var resV = cast(Prefs.screenSize, String);
		
    	if (resV != null && !FlxG.fullscreen) {
			var parts = resV.split('x');
			var res:Array<Int> = [for (i in 0...2) Std.parseInt(parts[i])];
			
    		FlxG.resizeGame(res[0], res[1]);
			Application.current.window.width  = res[0];
			Application.current.window.height = res[1];
    	}
	}

	public static function getDirectorySize(path:String):Float {
        var size:Float = 0;

        if (!FileSystem.exists(path)) return 0;

        for (item in FileSystem.readDirectory(path)) {
            var fullPath = '$path/$item';
            if (FileSystem.isDirectory(fullPath)) size += getDirectorySize(fullPath); else {
                try {
                    size += FileSystem.stat(fullPath).size;
                } catch (e:Dynamic) trace('Failed to get size of $fullPath: $e');
            }
        }

        return size;
    }
}

class UtilText extends FlxText {
    // Motherfuckin' Sexy high quality text!!!!!!!!!! yes
    // All it does is decrease the size to 0.5x and then doubling the size of the text
    public function new(x:Float = 0, y:Float = 0, fieldWidth:Float = 0, ?text:String, ?size:Int = 8, ?alignment:Null<FlxTextAlign>, ?borderStyle:Null<FlxTextBorderStyle>, ?borderColor:FlxColor, ?color:FlxColor, ?font:String) {
        super(x, y, fieldWidth * (Prefs.lowDetail ? 1 : 2), text);

        // Null Safety
        if(alignment   == null) alignment   = LEFT;
        if(borderStyle == null) borderStyle = OUTLINE;
        if(borderColor == null) borderColor = FlxColor.BLACK;
        if(color       == null) color       = FlxColor.WHITE;
        if(font        == null) font        = 'assets/fonts/main.ttf';

        this.setFormat(font, size * (Prefs.lowDetail ? 1 : 2), color, alignment, borderStyle, borderColor);
        if (!Prefs.lowDetail) {
            this.borderSize += this.borderSize;
            this.scale.x = 0.5;
            this.scale.y = 0.5;
            this.updateHitbox();
        }
        this.antialiasing = Prefs.antiAliasing;
    }
}