package demo.devserver;

class CompileAll
{
	public static function main () :Void
	{
		var x :Array<Dynamic> = [
			ExampleRemotingService,
			RemotingClient,
			RemotingServer,
			TestMessageType1,
			TestWebsocketClient,
			TestWebsocketRouter,
			TestWebsocketRouterClient,
			TestWebsocketServer
			];
		for (t in x) {
			trace(t);
		}
	}

}
