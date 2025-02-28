-- lol
local spawns = {
    objects = 0,
    grass = 0
}
local enemyData = {}
local canBeMoved = {}
local textToDel = {}
local levelData = {}
local lDNoSpawn = {}
local restrictItems = {"clearSky", "warrior", "tweenScore"}
local touchingGround = false
local ableToCheckJump = true
local jumped = false
local xPosMove = 0
local xPos = 0
local fallRate = 1
local textPopups = 0
local textDels = 0
local jumpCombo = 1

-- Gameplay Fun!
local sessionScore = 0
local coins = 0

function onCreatePost()
    hide('camHUD')
    hide('camGame')

    spriteMake('tweenScore', 0, 0, 0, 96, "000000", true)
    makeText('hudScore', 25, 15, 40)

    spriteMake('clearSky', 0,   0, 1920, 1080, "00AAFF", true)
    spriteMake('warrior',  0, 500,   32,   32, "0000FF", true)

    levelData = {
        {'grass',   0,    640, 1920,   96, "00FF00", true},
        {'grass',   2200, 590,  128,  128, "00FF00", true},
        {'grass',   2400, 420, 1000,   64, "00FF00", true},
        {'enemy',   1000, 420,   48,   48, "FF0000", true},
        {'enemy',   1100, 350,   48,   48, "FF0000", true},
        {'enemy',   1200, 420,   48,   48, "FF0000", true},
        {'enemy',   1300, 420,   48,   48, "FF0000", true},
        {'enemy',   1400, 420,   48,   48, "FF0000", true},
        {'enemy',   1500, 420,   48,   48, "FF0000", true},
        {'enemy',   1600, 420,   48,   48, "FF0000", true},
    }

    for i=1,10 do
        table.insert(levelData, {'coin', 740+(50*i), 590, 32, 32, "D4AF37", true})
    end

    for i=11,15 do
        table.insert(levelData, {'coin', 1400+(50*i), 520, 32, 32, "D4AF37", true})
    end

    setTextAlignment("hudScore", "left")
    setTextBorder("hudScore", 2, "333333")

    playSound("begin")
    runTimer("infLoopSong", 1.6)
end

function onUpdate(elapsed)
    for i=1,#levelData do
        if levelData[i][2] <= 1250 + xPos and not table.find(levelData[i][1]..i, lDNoSpawn) then
            spawns.objects = spawns.objects + 1
            table.insert(lDNoSpawn, levelData[i][1]..i)
            debugPrint(levelData[i][1]..i)
            spriteMake(levelData[i][1]..i, levelData[i][2], levelData[i][3], levelData[i][4], levelData[i][5], levelData[i][6], levelData[i][7])
        end
    end

    setTextString("hudScore", math.floor(getProperty("tweenScore.x")))
    doTweenX("weeScore", "tweenScore", sessionScore+0.5, 0.1, "linear")

    -- Movements
    if keyboardJustPressed("A") then
        restartSong(true)
    end

    xPosMove = xPosMove - ((keyboardPressed("Q") or keyboardPressed("A")) and 0.1 or 0)
    xPosMove = xPosMove + (keyboardPressed("D") and 0.1 or 0)

    if xPosMove ~= 0 then
        if xPosMove <= 0 then
            xPosMove = xPosMove + 0.05
        else
            xPosMove = xPosMove - 0.05
        end
    end

    if xPosMove <= -5 then
        xPosMove = -5
    end

    if xPosMove >= 5 then
        xPosMove = 5
    end

    setProperty("warrior.y", getProperty("warrior.y") + fallRate)
    fallRate = fallRate + 0.1
    if keyJustPressed('space') and not jumped and touchingGround then
        fallRate = -8
        jumped = true
        ableToCheckJump = false
        touchingGround = false
        runTimer("ableToCheckFall", 0.1, 1)
    else
        for i=1,spawns.grass do
            if ableToCheckJump then
                touchingGround = objectsOverlap("warrior", "grass"..i)
                if touchingGround then jumpCombo = 0.5 break end
            end
        end

        if touchingGround then
            fallRate = 0
            if jumped then
                for i=1,spawns.grass do
                    if objectsOverlap("warrior", "grass"..i) then
                        jumped = false
                        break
                    end
                end
            end
        end
        
        --[[for i=1,spawns.grass do
            if objectsOverlap("warrior", "grass"..i) then
                xPosMove = 0
                break
            end
        end]]
    end

    xPosMove = string.format("%.2f",xPosMove)
    xPos = xPos + xPosMove
    setProperty("warrior.x", 624 + xPosMove*16)

    -- Stage Properties
    local enemyToLook = 0
    for i=1,#canBeMoved do
        setProperty(canBeMoved[i][1]..".x", -xPos+canBeMoved[i][2])

        -- Enemy behavior
        if stringStartsWith(canBeMoved[i][1], "enemy") then
            enemyData[enemyToLook][2] = enemyData[enemyToLook][2] - 1
            setProperty(canBeMoved[i][1]..".x", (enemyData[enemyToLook][1] + enemyData[enemyToLook][2]) - xPos)

            if jumped and objectsOverlap("warrior", canBeMoved[i][1]) then
                jumpCombo = jumpCombo * 2
                fallRate = -5
                increaseScore(100 * jumpCombo)
                removeLuaSprite(canBeMoved[i][1])
            end

            for ii=1,spawns.grass do
                enemyData[enemyToLook][3] = objectsOverlap(canBeMoved[i][1], "grass"..ii)
                if enemyData[enemyToLook][3] then break end
            end

            if not enemyData[enemyToLook][3] then
                enemyData[enemyToLook][4] = enemyData[enemyToLook][4] + 0.1
                setProperty(canBeMoved[i][1]..".y", getProperty(canBeMoved[i][1]..".y") + enemyData[enemyToLook][4])
            else
                enemyData[enemyToLook][4] = 0
            end
        end
        debugPrint(enemyToLook)

        -- Detections
        if objectsOverlap("warrior", canBeMoved[i][1]) and stringStartsWith(canBeMoved[i][1], "coin") then
            increaseScore(50)
            removeLuaSprite(canBeMoved[i][1])
            playSound("confirmMenu")
            coins = coins + 1
        end
    end
end

function onStartCountdown()
    return Function_Stop
end

function onTweenCompleted(tag)
    if stringStartsWith(tag, "weFly") then
        textDels = textDels + 1
        removeLuaText(textToDel[textDels])
    end
end

function onTimerCompleted(tag, loops, loopsLeft)
    if tag == "ableToCheckFall" then
        ableToCheckJump = true
    end
    if tag == "infLoopSong" then
        playSound("game")
        runTimer("infLoopSong", 50.35)
    end
end

function spriteMake(name, x, y, width, height, color, center)
    local restriction = false
    for i=1,#restrictItems do
        if name == restrictItems[i] then
            restriction = true
            break
        end
    end
    if not restriction then
        table.insert(canBeMoved, {name, x})
        if stringStartsWith(name, "grass") then
            spawns.grass = spawns.grass + 1
        end
        if stringStartsWith(name, "enemy") then
            -- x, x moved, touched ground, fall rate
            table.insert(enemyData, {x, 0, false, 0})
        end
    end
    makeLuaSprite(name, "", 0, 0)
    makeGraphic(name, width, height, color)
    addLuaSprite(name)
    setObjectCamera(name, "other")
    setProperty(name..".x", x)
    setProperty(name..".y", y)
    if center then
        screenCenter(name)
        setProperty(name..".y", y)
    end
end

function makeText(name, x, y, size)
    makeLuaText(name, name, 1280, x, y)
    setTextSize(name, size)
    setTextAlignment(name, 'CENTER')
    addLuaText(name)
    setObjectCamera(name, 'camOther')
    setTextBorder(name, 0)
end

function hide(tag)
    setProperty(tag..'.alpha', 0)
end

function show(tag)
    setProperty(tag..'.alpha', 1)
end

function increaseScore(v)
    sessionScore = sessionScore + v
    textPopups = textPopups + 1
    local opti = 'scorePopup'..textPopups
    makeText(opti, getProperty("warrior.x")-5, getProperty("warrior.y")-20, 40)
    setTextAlignment(opti, "left")
    setTextBorder(opti, 2, "000000")
    setTextString(opti, v)
    doTweenY('weFly'..textPopups, opti, getProperty("warrior.y") - 200, 0.7, "linear")
    table.insert(textToDel, opti)
end

-- Finding an element in a table.
-- https://stackoverflow.com/questions/656199/search-for-an-item-in-a-lua-list
function table.find(f, t)
    for i=1,#t do
        if t[i] == f then
            return true
        end
    end
    return false
end