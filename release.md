This is the [] release of LuApps, bringing you more and more fancy features every update.

# Additions

- Assets: Icon: Added a new icon thanks to @SyncGit12
- DummyState: Will Load the new icon when exited out of LuApp.
- OptionsState: Improved Layering, Info texts are now in front instead of back.
- PlayState: Improved Layering, notifications are in the front, utils are in the 2nd layer, apps are in the 3rd layer and vice versa.
- PlayState: Added Trailing to Apps.
- PlayState: Added Gradient to Sprites and Apps.
- Repo: Added `alsoft` support, it does not do anything at the moment until i can get it to work.
- Modding: Added `gradient` support `pack.json`.
- Modding: Added the following Lua APIs:
```lua
mouseReleased()
mouseJustReleased()
keyReleased()
keyJustReleased()
formatBytes()
formatMoney()
formatTime()
setBrightness()

-- Read all the documentation at https://github.com/NAEL2XD/LuApps/wiki/All-LUA-APIs.-(Functions,-Variables-and-Events.)
```

# Changes

- Entire Repo: Optimized a LOT to increase performance.
- Wiki: LuAPI: Improved Args and Documentation.
- CrashHandler: Changed the Text size `16` > `24`.
- PlayState: Decreased `maxYPos` to `-20`.

# Bug Fixes

- PlayState: Fix a Crash when `pack.json`'s `gradient` variable isn't found or badly used.
- PlayState: Fix Background Still Scrolling when it's touching the ground fully or at the ceiling.

# Removals

- PlayState: Removed Useless Imports to Save Time and increase Performance.
- PlayState: Removed Camera named `camNotifs` since it was useless.