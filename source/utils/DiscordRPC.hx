package utils;

class DiscordRPC {
    public static var isInitialized:Bool = false;

    public static function prepare() {
        if (!isInitialized) initialize();

        Application.current.window.onClose.add(function() if(isInitialized) shutdown());
    }

    static function shutdown() {
        isInitialized = false;
        Discord.Shutdown();
    }

	static function initialize():Void {
        if (!Prefs.discordRPCAllow) return;
		Sys.println('Initializing Discord RPC...');

		final handlers:DiscordEventHandlers = new DiscordEventHandlers();
		handlers.ready = cpp.Function.fromStaticFunction(onReady);
		handlers.disconnected = cpp.Function.fromStaticFunction(onDisconnected);
		handlers.errored = cpp.Function.fromStaticFunction(onError);
		Discord.Initialize("1365681122519941291", cpp.RawPointer.addressOf(handlers), false, null);

		Thread.create(() ->  {
            while (true) {
                if (isInitialized) {
                    #if DISCORD_DISABLE_IO_THREAD
                    Discord.UpdateConnection();
                    #end
                    Discord.RunCallbacks();
                }

                // Wait 1 second until the next loop...
                Sys.sleep(1.0);
            }
        });

        isInitialized = true;
	}

	private static function onReady(request:cpp.RawConstPointer<DiscordUser>):Void {
		final username:String = request[0].username;
		final globalName:String = request[0].username;

		Sys.println('Discord: Connected to user @${username} ($globalName)');
	}

    public static function changePresence(state:String, details:String) {
        if (!Prefs.discordRPCAllow) return;
        
        final presence:DiscordRichPresence = new DiscordRichPresence();
		presence.type = DiscordActivityType_Playing;
		presence.state = details;
		presence.details = state;
        presence.largeImageText = 'v${Main.luversion}';

		final button:DiscordButton = new DiscordButton();
		button.label = "Source Code";
		button.url = "https://github.com/NAEL2XD/LuApps";
		presence.buttons[0] = button;

		Discord.UpdatePresence(cpp.RawConstPointer.addressOf(presence));
    }

	private static function onDisconnected(errorCode:Int, message:cpp.ConstCharStar):Void Sys.println('Discord: Disconnected ($errorCode:$message)');

	private static function onError(errorCode:Int, message:cpp.ConstCharStar):Void Sys.println('Discord: Error ($errorCode:$message)');
}