package;

import flixel.FlxState;
import flixel.FlxSprite;
import flixel.FlxGroup;
import flixel.FlxTween;
import flixel.FlxSound;
import flixel.util.FlxColor;
import flixel.util.FlxEase;

class OptionsState extends FlxState {

    // Options and state settings
    var options:Array<Array<Dynamic>> = [
        ["LuApps Settings",  "Have too many LuApps but want to show something else? Now you can set them here.", "State"],
        ["Show Type",        "What type of LuApps you want to show?",                                            "String", "luAppsType", ["ALL"]],
        ["Calculate Size",   "Whether or not you want to calculate the size of a LuApp file.",                  "Bool",   "calculateSize"],
        ["Graphics",         "Set your graphic settings, from beautiful to toaster.",                          "State"],
        ["Anti-Aliasing",    "If ON, most objects (especially images) will be sharp and clean.",               "Bool",   "antiAliasing"],
        ["Low Detail",       "If ON, most details (e.g., overlapping objects) will be removed.",              "Bool",   "lowDetail"],
        ["Framerate",        "Adjust the framerate.",                                                        "Int",    "framerate", [60, 240, 1, 7]],
        ["Resolution",       "Adjust the screen resolution.",                                                "String", "screenSize", ["640x360", "1280x720", "1920x1080"]],
        ["Shaders",          "Enable or disable shaders.",                                                  "Bool",   "shaders"],
        ["Visuals",          "Settings for disabling distracting elements.",                                 "State"],
        ["Allow Particles.", "If ON, particles will be used (increases CPU load).",                           "Bool",   "allowParticles"],
        ["Show FPS",         "If ON, FPS (with memory count) will be shown.",                               "Bool",   "showFPS"],
        ["Notifications",    "If ON, notifications will be shown.",                                           "Bool",   "notification"],
        ["Discord RPC",      "If ON, Discord RPC will be enabled to show your game to others.",              "Bool",   "discordRPCAllow"],
        ["Debugging",        "Developer options.",                                                           "State"],
        ["Restart by [R]",   "If ON, pressing [R] will restart the LuApps. Only for developers!",             "Bool",   "restartByR"]
    ];

    var requiresRestart:Array<String> = ["Discord RPC"];
    var helpText:UtilText;
    var spriteList:Array<Array<FlxSprite>> = [];
    var textList:Array<Array<UtilText>> = [];
    var previewText:Array<Array<Dynamic>> = [];
    var currentLDStatus:Bool = Prefs.lowDetail;

    var yPos:Float = 0;
    var maxYPos:Float = 0;
    var isSettingThing:Bool = false;
    var allowMoving:Bool = true;
    var triggered:Bool = false;

    override public function create() {
        initializeSettings();
        initializeUI();
        setupMusic();
        setupHelpText();
    }

    // Initialize game settings and options.
    private function initializeSettings():Void {
        Main.changeWindowName("Settings");
        DiscordRPC.changePresence("On Settings", "Setting some Changes.");

        // Set up LuApps type options based on available Lua lists.
        options[1][4] = sortLuAppsTypes(PlayState.luaLists);

        for (option in options) {
            createOption(option);
        }
    }

    // Set up the user interface elements (sprites, text, etc.).
    private function initializeUI():Void {
        addOptionBackground();
        createOptionElements();
    }

    // Create the background for the options menu.
    private function addOptionBackground():Void {
        var optionsBG:FlxSprite = new FlxSprite().makeGraphic(1280, 720, 0xFF756C6C);
        optionsBG.alpha = 0;
        FlxTween.tween(optionsBG, {alpha: 1}, 0.5);
        add(optionsBG);
    }

    // Set up background music for the options menu.
    private function setupMusic():Void {
        FlxG.sound.playMusic('assets/music/settings.ogg', 1, true);
    }

    // Set up help text displayed on the options screen.
    private function setupHelpText():Void {
        helpText = new UtilText(0, 0, 1280, "Use your mouse and hold left click and move up or down to scroll. Left click on an option to change it.\nPress BACKSPACE or ESCAPE to leave options.", 24, CENTER, SHADOW, null, FlxColor.YELLOW);
        helpText.setBorderStyle(SHADOW, FlxColor.BLACK, 8, 8);
        helpText.screenCenter();
        helpText.y = 650;
        add(helpText);
    }

    // Sort LuApps types by their frequency in the game.
    private function sortLuAppsTypes(luaLists:Array<Dynamic>):Array<String> {
        var typeList:Array<String> = [for (thing in luaLists) thing[4]];
        var map:Map<String, Int> = new Map();

        // Count occurrences of each type.
        for (type in typeList) {
            if (map.exists(type)) {
                map.set(type, map.get(type) + 1);
            } else {
                map.set(type, 1);
            }
        }

        // Sort types by frequency and return the result.
        var sortedTypes:Array<String> = ["ALL"];
        for (key in map.keys()) {
            sortedTypes.push('${key} [${map.get(key)}]');
        }
        sortedTypes.sort((a, b) -> {
            var aCount = Std.parseInt(a.split("[")[1].split("]")[0]);
            var bCount = Std.parseInt(b.split("[")[1].split("]")[0]);
            return bCount - aCount;
        });

        return sortedTypes;
    }

    // Create and add UI elements (sprites, text) for each option.
    private function createOption(option:Array<Dynamic>):Void {
        var optionName:String = option[0];
        var optionType:String = option[2];
        var yOffset:Float = calculateYOffset(optionType);

        // Create preview text.
        createPreviewText(optionName, yOffset, optionType);

        if (optionType != "State") {
            createOptionUI(option, yOffset);
        } else {
            createStateOptionUI(option, yOffset);
        }
    }

    // Calculate the Y offset based on the option type (state or other).
    private function calculateYOffset(optionType:String):Float {
        var yOffset:Float = 0;
        if (optionType == "State") {
            yOffset = 160;
        } else {
            yOffset = 115;
        }
        return yOffset;
    }

    // Create preview text for the option.
    private function createPreviewText(optionName:String, yOffset:Float, optionType:String):Void {
        previewText.push([yOffset, new UtilText(10, yOffset, optionName.length * 13.75, optionName, 13, LEFT, NONE, null, null, 'assets/fonts/debug.ttf')]);
        previewText[previewText.length - 1][1].x += (optionType != "State" ? 20 : 0);
        add(previewText[previewText.length - 1][1]);
    }

    // Create standard UI elements for an option (not of type "State").
    private function createOptionUI(option:Array<Dynamic>, yOffset:Float):Void {
        var sprite:FlxSprite = new FlxSprite().makeGraphic(860, 105, 0xFF797979);
        sprite.screenCenter();
        sprite.y = 60 + yOffset;
        add(sprite);

        var text:UtilText = new UtilText(230, 75 + yOffset, 1280, option[0], 56);
        text.setBorderStyle(SHADOW, FlxColor.BLACK, PlayState.qSize, PlayState.qSize);
        add(text);

        var value:Dynamic = Reflect.getProperty(Prefs, option[3]);
        var valueText:UtilText = new UtilText(-240, 88 + yOffset - (currentLDStatus ? 6 : 0), 1280, '$value', 60, RIGHT, SHADOW);
        valueText.setBorderStyle(SHADOW, FlxColor.BLACK, PlayState.qSize, PlayState.qSize);
        valueText.underline = true;
        valueText.font = 'assets/fonts/settings.ttf';
        add(valueText);

        if (option[2] == "Bool") {
            valueText.text = value ? "ON" : "OFF";
        }
    }

    // Create UI for "State" type options (with descriptions).
    private function createStateOptionUI(option:Array<Dynamic>, yOffset:Float):Void {
        var nameText:UtilText = new UtilText(0, 90 +
