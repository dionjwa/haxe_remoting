package demo.devserver;

import transition9.websockets.WebsocketClient;
import js.Node;

class TestWebsocketRouterClient
{
	public static function main () :Void
	{
		var clientId = "client" + Std.int(Math.random() * 1000);
		var client = new WebsocketClient("ws://localhost:8000", clientId);
		client.connected.connect(function(client :WebsocketClient) {
			client.sendMessage(new TestMessageType1(clientId));
		});
		
		client.registerHandler(TestMessageType1, function(msg :TestMessageType1) {
			Log.info("Got a TestMessageType1: " + msg);
			Node.setTimeout(function() {
				client.sendMessage(new TestMessageType1(clientId));
			}, 2000);
			// client.sendMessage(new TestMessageType1(clientId));
		});
	}
	
	// public function new (ws_address :String, ?clientId :String)
	// {
	// 	super(ws_address, clientId);
	// }
	

}
