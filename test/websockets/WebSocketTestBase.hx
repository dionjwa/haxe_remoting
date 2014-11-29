package websockets;

// import com.dongxiguo.continuation.Async;

import haxe.Json;

import js.Node;
import js.node.WebSocketServer;

import tink.core.Pair;

class WebSocketTestBase
{
	public function new()
	{
	}

	public function setup(__return :Void->Void)
	{
		Log.info("WebSocketTestBase.setup");
		getWebsocketServer(
			function(ws :WebSocketServer, port :Int) {
				_webSocketServer = ws;
				_port = port;
				__return();
			});
	}

	public function tearDown(__return :Void->Void)
	{
		Log.info("WebSocketTestBase.teardown");
		WebSocketTools.closeWebSocketServer(_webSocketServer, __return);
	}

	//Callback takes the WebsocketServe and the port it's listening on.
	public function getWebsocketServer(cb :WebSocketServer->Int->Void)
	{
		WEBSOCKET_PORT_COUNTER++;
		var port = WEBSOCKET_PORT_COUNTER;
		WebSocketTools.buildWebSocketServer(port,
			function(ws :WebSocketServer) {
				cb(ws, port);
			});
	}

	var _port :Int;
	var _webSocketServer :WebSocketServer;
	static var WEBSOCKET_PORT_COUNTER :Int = 9999;
}