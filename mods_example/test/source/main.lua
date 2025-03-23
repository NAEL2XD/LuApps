-- Instead of "onCreate", we use "create"
function create()
    -- Cleans memory first before starting up.
    cleanMemory()

    -- makeSprite uses 4 args, 1 required and 3 aren't.
    -- tag, image, x, y
    makeSprite("lol", "test")

    -- Adds a sprite
    addSprite("lol")

    -- Text uses 5 args now
    makeText('text', 'is it working?', 1280, 40, 40)

    setTextSize("text", 48)                -- Size?
    setTextString("text", "yeah it does!") -- String?
    setTextColor("text", "675D2A")         -- Color?
    -- I can't show the full version.

    -- Add text
    addText("text")

    -- Plays music!
    playMusic("Inst")

    -- Resizes window.
    setWindowSize(640, 360)

    -- Checks if it's fullscreen
    if not fullscreen then
        print("You like borderless?")
    end

    -- Prints output on console.
    print("Hello!")

    -- Move an object's x coordinate to 50
    setProperty("lol.x", 50)

    -- Get lol's x variable and print it's value + 50
    local x = getProperty("lol.x")
    print(x + 50)

    -- Set shading.
    setBlend('lol', 'LIGHTEN') -- LIGHTEN!

    -- Tweens too!
    doTweenX("xd", "lol", 0, 1, "linear")

    -- mouse movement check
    makeText("mousemovechk", "?", 1920, 240, 160)
    addText("mousemovechk")

    -- Plays sound aswell
    playSound("tri")
    playSound("fnf_loss_sfx")

    -- The width and height the window is
    print(width .. " | " .. height)

    --
    makeText("awesome", "this is the coolest", 1280, 60, 60)
    setTextBorderStyle("awesome", "shadow", "00DD00", 4, 4) -- STYLISH border! 2nd argument only can be shadow, outline and outlinefast. default is none.
    addText("awesome")

    setBlend("awesome", "lighten") -- light

    print(randomInt(0, 50)) -- Gets random int between 0 and 50.
    print(randomFloat(0, 50)) -- Gets random float between 0 and 50.
    print(randomBool(50)) -- Gets random bool, i might get a true and you get a false.

    print(author) -- Prints who made it, it's "Nael2xd"

    print(osName) -- The current os running, i'll get "Generic PnP Monitor".

    sendPopup("", "HEY!") -- Window Popup.

    makeText("textread", getContent("text.txt"), 1920, 0, 180)
    setTextSize("textread", 28)
    screenCenter("textread") -- centers a text to screen
    addText("textread")

    print(version) -- The current version of LuApps

    print(lowDetail) -- Checks if the user's Low Detail option, if it's on then it returns true, else it returns false.

    runHaxeCode([[
        var sound:FlxSound = FlxG.sound.load('mods/test/assets/music/Inst.ogg');
		sound.pitch = 1.5;
		sound.play();
    ]]) -- Plays audio at 1.5x speed

    resetWindowSize() -- sets the window size to prefs set
end

local enable = true
-- On every frame pass, call an update, It's not "onUpdate".
function update()
    setWindowName("Hello, my name is window!") -- Sets the window name next to the icon.

    -- time variable gets the time on how long has it ran.
    print(time)

    -- Set the visibility! Beware, it cause lag.
    setMouseVisibility()

    -- Checks if any is pressed.
    if mouseClicked("any") and enable then
        -- Or middle or right!
        if mouseClicked("middle") or mouseClicked("right") then
            print("left click is bad! so we will disable it")
            enable = false
            return
        end

        print("left go click!")
    end

    -- What if it's held too?
    if mousePressed("any") then
        print("Wow!")
    end

    -- Checks if a key is pressed, leave empty for any.
    if keyJustPressed() then
        -- Or check if "W" is pressed.
        if keyJustPressed("W") then
            print("The W!")
            return
        end

        -- Crash test.
        if keyJustPressed("C") then
            -- This does not do anything and is not found on LuaEngine.hx so they will get an error.
            crash()
        end

        print("W isn't my type.")
    end

    -- Mouse Properties
    setTextString("mousemovechk", "Mouse X: " .. mouseX .. "\nMouse Y: " .. mouseY)

    moveTowardsMouse("lol", 800) -- I'm gonna catch you!
end
