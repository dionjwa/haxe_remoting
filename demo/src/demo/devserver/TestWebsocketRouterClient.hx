package demo.devserver;

import transition9.websockets.WebsocketClient;
import js.Node;

class TestWebsocketRouterClient
{
	public static function main () :Void
	{
		var clientId = "client" + Std.int(Math.random() * 1000);
		var client = new WebsocketClient("ws://localhost:8001", clientId);
		client.connected.connect(function(client :WebsocketClient) {
			client.sendObj(new TestMessageType1(clientId));
		});
		
		client.registerMessageHandler(function(msg :demo.devserver.TestMessageType1) {
			Log.info("Got a TestMessageType1: " + msg);
			Node.setTimeout(function() {
				client.sendObj(new TestMessageType1(clientId));
			}, 2000);
		});
	}
}
