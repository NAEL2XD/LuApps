@echo off
color 0a
cd ..
echo Installing dependencies...
echo This might take a few moments depending on your internet speed.
@echo on
haxelib install lime 8.1.3
haxelib install openfl 9.3.3
haxelib git flixel https://github.com/moxie-coder/flixel 5.6.2
haxelib install flixel-addons 3.3.2
haxelib install flixel-tools 1.5.1
haxelib install flixel-ui 2.6.1
haxelib install hscript
haxelib install hxcpp-debug-server
haxelib git hxcpp https://github.com/HaxeFoundation/hxcpp/
haxelib git hxdiscord_rpc https://github.com/MAJigsaw77/hxdiscord_rpc
haxelib install hxvlc 1.9.2
@echo off
echo Finished!
pause
