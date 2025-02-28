import os.path
import sys

if not os.path.exists("import.lua"):
    print("import.lua does not exist!")
    sys.exit(1)

og = open('import.lua', 'r')
convert = f"-- Converted using Nael's PE Script to LUAPPS Compatible\n\n{og.read()}"

def removeLinesWithKeyword(text, keyword):
    lines = text.splitlines()
    
    filtered_lines = [line for line in lines if keyword not in line]
    
    return "\n".join(filtered_lines)


replace = [
    [
        # Events
        ['onCreatePost', 'create'],
        ['onCreate', 'create'],
        ['onUpdate', 'update'],
        ['onTweenCompleted', 'tweenComplete'],

        # Variables
        ['framerate', 'fps'],

        # Functions
        ['debugPrint', 'print'],
        ['removeLuaText', 'removeText'],
        ['removeLuaSprite', 'removeSprite'],
        ['makeSprite', 'peMakeSprite'],
        ['makeLuaSprite', 'makeSprite'],
        ['spriteMake', 'peSpriteMake'],
        ['makeText', 'peMakeText'],
        ['makeLuaText', 'makeText'],
        ['addLuaSprite', 'addSprite'],
        ['addLuaText', 'addText'],
        ['getRandomInt', 'randomInt'],
        ['getRandomFloat', 'randomFloat'],
        ['getRandomBool', 'randomBool'],
        ['keyboardJustPressed', 'keyJustPressed'],
        ['keyboardPressed', 'keyPressed']
    ],
    [
        "setObjectCamera",
        "restartSong",
        "exitSong",
        "getDataFromSave",
        "setDataFromSave",
        "flushSaveData",
        "setPropertyFromClass",
        "makeAnimatedLuaSprite",
        "addAnimationByPrefix",
        "setObjectOrder",
        "changePresence"
    ]
]

for i in range(len(replace[0])):
    convert = convert.replace(replace[0][i][0], replace[0][i][1])

for i in range(len(replace[1])):
    convert = removeLinesWithKeyword(convert, replace[1][i])

save = open('export.lua', 'w')
save.write(convert)
save.close()