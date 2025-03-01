All of the LUA APIs in this page!

Includes all VARIABLES, FUNCTIONS and EVENTS on all and what they do!

If there's something below, but don't know what they do? You can use CTRL+F and find which function or variable and then see what it does for the function, event or variable!

<small>This was generated, click [here](https://github.com/NAEL2XD/LuApps/blob/main/extras/main.py) for the code.</small>

There are a total of:
* 52 functions.
* 14 variables.
* 3 events.

# Functions
### `print(text:String)`
Prints to console.

### `makeSprite(tag:String, ?image:String, ?x:Float = 0, ?y:Float = 0)`
Spawns a Sprite with no animations using the tag `tag`, it will be using the image `image`.png, and will be spawned on position `x`, `y` If you want to make a Black screen with no texture, leave `image` field empty and use [makeGraphic](https://github.com/NAEL2XD/LuApps/wiki/All-LUA-APIs.-(Functions,-Variables-and-Events.)#makegraphicobjstring-widthint--256-heightint--256-colorstring--ffffff)

If another Sprite that exists is already using the tag `tag`, it will be removed.

### `addSprite(tag:String, front:Bool = false)`
Adds a Sprite with the specified tag, either in front or behind the characters.

### `removeSprite(tag:String)`
Removes Sprite with the specified tag
* `tag` - The Sprite's tag

### `makeText(tag:String, text:String, width:Int, x:Float, y:Float)`
Creates Text object on position `x`, `y` and a width with 'width'

### `addText(tag:String)`
Spawns Text on the stage

### `removeText(tag:String, destroy:Bool = true)`
Removes Text with the specified tag
* `tag` - The Sprite's tag

### `setTextString(tag:String, text:String)`
Sets text string at the specified tag

### `setTextSize(tag:String, size:Int)`
Sets text size at the specified tag

### `setTextBorder(tag:String, size:Int, color:String)`
Sets text border at the specified tag

### `setTextBorderStyle(tag:String, style:String, hexColor:String, ?size:Float = 1, ?quality:Float = 1)`
Sets the text's border into a very special style.

* `tag` - The text's tag.
* `style` - What style do you wanna use? Available options: `shadow`, `outline`, `outlinefast`. default is `none`
* `hexcolor` - Ditto, what hex do you wanna use.
* `size` - Size of the border, will be 1 if default.
* `quality` - The quality of the border, will likely lag if it's too high.

### `setTextColor(tag:String, color:String)`
Sets text color at the specified tag

### `setTextFont(tag:String, font:String)`
Sets text font at the specified tag

### `setTextAlignment(tag:String, alignment:String = 'left')`
Sets text alignment at the specified tag `'left'`,`'right'`, or `'center'`

### `playMusic(music:String, ?volume:Float = 1, ?loop:Bool = false)`
* `music` - File name (Should be located in `mods/modName/music/`)
* `volume` - Optional value, volume percent goes from `0` to `1`. Default value: `1`
* `volume` - Optional value, if the music should loop indefinitely. Default value: `false`

### `setWindowSize(?width:Int = 1280, ?height:Int = 720)`
Sets the window size for you
* `width` - Width by pixels
* `height` - Height by pixels

### `setProperty(variable:String, value:Dynamic)`
Works in the same way as `getProperty()`, but it sets a new value for the variable.

Also returns the new value of the variable.

Example: To move a sprite's `x` variable, use `setProperty('sprite.x', 50)`

### `getProperty(variable:String)` -> `?`
Returns a current variable from Dummy's state.

It can also be used to get the variable from an object that is inside Dummy or a Sprite.

Example: If you wanted to get the current sprite's `x` value, you should use `getProperty('sprite.x') -> 50`

### `keyJustPressed(?key:String)` -> `boolean`
Checks if specific keyboard key was pressed on that frame, will be false if the frame passes.

[List of Keys](https://api.haxeflixel.com/flixel/input/keyboard/FlxKeyList.html)

### `keyPressed(?key:String)` -> `boolean`
Checks if specific keyboard key was pressed on any frame.

[List of Keys](https://api.haxeflixel.com/flixel/input/keyboard/FlxKeyList.html)

### `mouseClicked(?key:String)` -> `boolean`
Get if the mouse button `key` just got pressed on the current frame. leave 'name' blank for left mouse

Buttons: `'left'`, `'right'`, `'middle'`, `'any'`

### `mousePressed(?key:String)` -> `boolean`
Get if the mouse button `key` is being held on the current frame.

Buttons: `'left'`, `'right'`, `'middle'`, `'any'`

### `setBlend(obj:String, blend:String = '')`
Changes the blend mode of a Sprite (Works similar to how Photoshop do it)
* `obj` - Sprite tag or Object variable name
* `blend` - Blend mode to use. Example: `add`, `darken`, `normal`.

[Lists of blend modes.](https://api.haxe.org/flash/display/BlendMode.html)

### `doTweenX(tag:String, vars:String, value:Dynamic, duration:Float, ease:String)`
Do a Tween on an object's X value

**Calling this function will cancel another tween that is using the same tag!**
* `tag` - Once the tween is finished, it will do a callback of `onTweenCompleted(tag)`
* `vars` - Variable to tween, example: `sprite` for tweening sprite's X position, `sprite.scale` for tweening sprite's Scale X
* `value` - Target value on the tween end
* `duration` - How much time it will take for the tween to end
* `ease` - The tweening method used, example: `linear`, `circInOut`. Check the link on the note i've added up here

Example: To do a tween to sprite's Scale X, you should use `doTweenX('tween', 'sprite.scale', 1.5, 1, 'elasticInOut')`, when the tween ends, it will do a callback for `onTweenCompleted('tween')`
[Lists of tween that can be done.](https://api.haxeflixel.com/flixel/tweens/FlxEase.html)

### `doTweenY(tag:String, vars:String, value:Dynamic, duration:Float, ease:String)`
Do a Tween on an object's Y value

**Calling this function will cancel another tween that is using the same tag!**
* `tag` - Once the tween is finished, it will do a callback of `onTweenCompleted(tag)`
* `vars` - Variable to tween, example: `sprite` for tweening sprite's X position, `sprite.scale` for tweening sprite's Scale X
* `value` - Target value on the tween end
* `duration` - How much time it will take for the tween to end
* `ease` - The tweening method used, example: `linear`, `circInOut`. Check the link on the note i've added up here

Example: To do a tween to sprite's Scale X, you should use `doTweenX('tween', 'sprite.scale', 1.5, 1, 'elasticInOut')`, when the tween ends, it will do a callback for `onTweenCompleted('tween')`
[Lists of tween that can be done.](https://api.haxeflixel.com/flixel/tweens/FlxEase.html)

### `doTweenAngle(tag:String, vars:String, value:Dynamic, duration:Float, ease:String)`
Do a Tween on an object's Angle value

**Calling this function will cancel another tween that is using the same tag!**
* `tag` - Once the tween is finished, it will do a callback of `onTweenCompleted(tag)`
* `vars` - Variable to tween, example: `sprite` for tweening sprite's X position, `sprite.scale` for tweening sprite's Scale X
* `value` - Target value on the tween end
* `duration` - How much time it will take for the tween to end
* `ease` - The tweening method used, example: `linear`, `circInOut`. Check the link on the note i've added up here

Example: To do a tween to sprite's Scale X, you should use `doTweenX('tween', 'sprite.scale', 1.5, 1, 'elasticInOut')`, when the tween ends, it will do a callback for `onTweenCompleted('tween')`
[Lists of tween that can be done.](https://api.haxeflixel.com/flixel/tweens/FlxEase.html)

### `doTweenAlpha(tag:String, vars:String, value:Dynamic, duration:Float, ease:String)`
Do a Tween on an object's Alpha value

**Calling this function will cancel another tween that is using the same tag!**
* `tag` - Once the tween is finished, it will do a callback of `onTweenCompleted(tag)`
* `vars` - Variable to tween, example: `sprite` for tweening sprite's X position, `sprite.scale` for tweening sprite's Scale X
* `value` - Target value on the tween end
* `duration` - How much time it will take for the tween to end
* `ease` - The tweening method used, example: `linear`, `circInOut`. Check the link on the note i've added up here

Example: To do a tween to sprite's Scale X, you should use `doTweenX('tween', 'sprite.scale', 1.5, 1, 'elasticInOut')`, when the tween ends, it will do a callback for `onTweenCompleted('tween')`
[Lists of tween that can be done.](https://api.haxeflixel.com/flixel/tweens/FlxEase.html)

### `doTweenColor(tag:String, vars:String, targetColor:String, duration:Float, ease:String)`
Do a Tween on an object's color

**Calling this function will cancel another tween that is using the same tag!**
* `tag` - Once the tween is finished, it will do a callback of `onTweenCompleted(tag)`
* `vars` - Variable to tween, example: `sprite` for tweening sprite's X position, `sprite.scale` for tweening sprite's Scale X
* `targetColor` - The color the object will have when the tween ends (Must be in hexadecimal!)
* `duration` - How much time it will take for the tween to end
* `ease` - The tweening method used, example: `linear`, `circInOut`. Check the link on the note i've added up here

Example: To tween sprite's color to Red, you should use `doTweenColor('tween', 'sprite', 'FF0000', 1, 'linear')`, when the tween ends, it will do a callback for `onTweenCompleted('tween')`
[Lists of tween that can be done.](https://api.haxeflixel.com/flixel/tweens/FlxEase.html)

### `setMouseVisibility(?show:Bool = true)`
Sets the visibility for the cursor.
* `show` - Whatever or not you want to show the cursor icon.

### `playSound(sound:String)`
Plays sound from mods/raw/sounds.
* `sound` - Name of the file to play.

### `moveTowardsMouse(tag:String, speed:Int = 60)`
Moves the sprite to the mouse's `x` and `y` position.

* `tag` - The sprite tag.
* `speed` - What speed do you wanna use? Defaults to 60 if empty.

### `sendPopup(?title:String = "", desc:String = "")`
Sends a window popup from the engine.

* `title` - Title for your window popup, leave empty for `modName`. 
* `desc` - Description for your window popup, will be an error if nothing is set.

### `randomInt(?min:Int = 1, ?max:Int = 10)` -> `number`
Gets min and max, randomizes the integer and returns the result.

* `min` - Minimum for the integer. Default is 1.
* `max` - Maximum for the integer. Default is 10.

### `randomFloat(?min:Int = 0, ?max:Int = 1)` -> `number`
Same as `randomInt` but it's returning a random float.

* `min` - Minimum for the float. Default is 0.
* `max` - Maximum for the float. Default is 1.

### `randomBool(?chance:Float = 50)` -> `boolean`
Returns `true` or `false` depending on how high your chance is and how large the number is.

* `chance` -  How low or high you want the chances, can be 0 - 100. Default is 50.

### `cleanMemory()`
Uses garbage collect to clean memory.

***WARNING:***
Doing this multiple amount of times can cause lag spikes, so be careful and do not make it trigger every frame!
You should put it on `create` function.

### `makeGraphic(obj:String, ?width:Int = 256, ?height:Int = 256, ?color:String = "FFFFFF")`
Used for making an object use a solid color Width x Height frame instead of a texture.
* `obj` - Lua Sprite tag or Object variable name
* `width` - Width in pixels of the graphic you want to create
* `height` - Height in pixels of the graphic you want to create
* `color` - Color string, works the same as `getColorFromHex()`

Example: Use `makeGraphic('testBlackSquare', 1000, 1000, '000000')` to make the Lua Sprite with the tag "testBlackSquare" turn into a 1000x1000 black square.

### `screenCenter(obj:String, ?pos:String = 'xy')`
Centers a object on screen

### `stringEndsWith(str:String, end:String)` -> `boolean`
Checks if `str` ends with `end`

### `stringSplit(str:String, split:String)` -> `array`
Splits string with `split` delimeter to array of strings

### `stringStartsWith(str:String, start:String)` -> `boolean`
Checks if `str` starts with `start`

### `stringTrim(str:String)` -> `string`
Removes empty characters from the beginning and end of `string`

### `scaleObject(obj:String, x:Float, y:Float)`
Scales an object/tag with the listed arguments
* `obj` - Your sprite/text tag.
* `x` - Scale to X, Set to 1 for default.
* `y` - Scale to Y, Set to 1 for default.

### `runTimer(tag:String, time:Float = 1, loops:Int = 1)`
Runs a timer with a determined duration and loops count.

**Calling this function will cancel another timer that is using the same tag!**
* `tag` - Once the timer is finished, it will do a callback of `timerCompleted(tag, loops, loopsLeft)`
* `time` - Optional value, how much time it takes to finish a loop. Default value is `1`
* `loops` - Optional value, how much loops should it do, if it's set to `0`, it will repeat indefinitely. Default value is `1`

### `cancelTimer(tag:String)`
Cancels a timer using the tag `tag`, if there even is one.

### `cancelTween(tag:String)`
Cancels a tween using the tag `tag`, if there even is one.

### `getContent(file:String = '')` -> `string`
Gets the file, reads it and returns the String.

**Make sure the file exists, if it doesn't then warning is thrown.**

`file` - File path inside `mods/raw/assets/data`

### `getColorFromFlx(color:String = '')` -> `FlxColor`
Gets the color from FlxColor and returns it's color value.

* `color` - The color you want to use.

**If `color` is empty, it will use the `WHITE` color.**

[Lists of FlxColor that can be used](https://api.haxeflixel.com/flixel/util/FlxColor.html)

### `setWindowName(name:String)`
Sets the window name next to the icon.

* `name` - The name of the window you want to set, defaults to `LuApps v{version} - modName`.

### `objectsOverlap(obj1:String, obj2:String)` -> `boolean`
Checks if `obj1` and `obj2` are colliding, returns `true` if they're colliding, will return `false` if they aren't.

* `obj1` - The first object tag to choose.
* `obj2` - The second object tag to choose.

### `runHaxeCode(codeToRun:String)` -> `?`
Runs haxe code and either returns the result you've inputted or changes how it looks.

* `codeToRun` - The haxe code to run.

### `addHaxeLibrary(libName:String, ?libPackage:String = '')`
Adds a haxe module for HScripts.

* `libName` - The library name from haxelib.
* `libPackage` - The package name from haxelib.


# Variables
### `author` -> `string`
The current author that made the mod.

### `fullscreen` -> `boolean`
Whatever or not if the fullscreen is used or not.

### `height` -> `number`
Gets the height of the window.

### `mouseMoved` -> `boolean`
Checks if the mouse is moved or not.

### `mouseX` -> `number`
Gets the mouse's `x` position.

### `mouseY` -> `number`
Gets the mouse's `y` position.

### `width` -> `number`
Gets the width of the window.

### `fps` -> `number`
Fetches the FPS that it's using.

### `modName` -> `string`
The name of the mod launched from PlayState.

### `modRaw` -> `string`
The path of the mod next to the engine that it's running.

### `time` -> `number`
Sees how long has it ran for.

### `osName` -> `string`
Gets the running Operating System's Name.

An example would be if you're running '**Generic PnP Monitor**'.

### `version` -> `string`
The current version of LuApps, should be returning something like `0.0.1`.

### `lowDetail` -> `boolean`
The current setting if the user has set "Low Detail" to on or off.


# Events
### `create()`
Function called when script is loaded.

### `update(elapsed:Float)`
Function called when script moves 1 frame.

### `tweenComplete(tag:String)`
Function called when a tween is completed.

