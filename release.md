This is the 3rd release of LuApps, bringing you more and more fancy features every update.

# Additions

- Assets: Icon: Added a new icon thanks to @SyncGit12
- Game: Added a `Example LuApp.luapp` file on `mods/` when downloaded on release.
- DummyState: Will Load the new icon when exited out of LuApp.
- OptionsState: Improved Layering, Info texts are now in front instead of back.
- OptionsState: Added an option to toggle the size calculation or not.
- PlayState: Improved Layering, notifications are in the front, utils are in the 2nd layer, apps are in the 3rd layer and vice versa.
- PlayState: Added Trailing to Apps.
- PlayState: Added Gradient to Sprites and Apps.
- ~~Repo: Added `alsoft` support, it does not do anything at the moment until i can get it to work.~~ Nevermind
- Modding: Added `gradient` support for `pack.json`.
- Modding: Added the following Lua APIs:
```lua
-- Functions
mouseReleased()
mouseJustReleased()
keyReleased()
keyJustReleased()
formatBytes()
formatMoney()
formatTime()
setBrightness()
mouseOverlaps()
getSeconds()   
getMinutes()   
getHours()     
getDay()       
getWeekDay()   
getMonth()     
getFullYear()  
getTime()      
getTimeFormat()
quickFile()
saveContent()
debugger()

-- Read all the documentation at https://github.com/NAEL2XD/LuApps/wiki/All-LUA-APIs.-(Functions,-Variables-and-Events.)
```

# Changes

- Entire Repo: Optimized a LOT to increase performance.
- Entire Repo: Move Imports to Import.hx.
- Game: Improved text readability, now it looks smooth when fullscreened at a 1080p monitor.
- Game: Use Flixel Mouse as it's default.
- Wiki: LuAPI: Improved Args and Documentation.
- CrashHandler: Changed the Text size `16` > `24`.
- PlayState: Decreased `maxYPos` to `-20`.
- PlayState: Decreased `author` y pos to `118`
- Modding: `time` now pauses when you are in the Pause Substate.

# Bug Fixes

- PlayState: Fix a Crash when `pack.json`'s `gradient` variable isn't found or badly used.
- PlayState: Fix Background Still Scrolling when it's touching the ground fully or at the ceiling.
- Game; Modding: Mistakenly used folder name instead of the file name.
- OptionsState: Fix Integers not incrementing/decrementing when keys required are held down.
- OptionsState: Fix String type changing options each frame when a key is held.

# Removals

- PlayState: Removed Useless Imports to Save Time and increase Performance.
- PlayState: Removed Camera named `camNotifs` since it was useless.