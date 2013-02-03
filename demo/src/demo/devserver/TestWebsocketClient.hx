package demo.devserver;

import transition9.remoting.NodeJsHtmlConnection;
import js.node.WebSocketNode;
import js.Node;

class TestWebsocketClient
{
	public static function main()
	{
		//https://github.com/visionmedia/commander.js
		var program :Dynamic= Node.require('commander');
		program
			.version('0.0.1')
			.option('-w, --websocketport <websocketport>', 'specify the port [8081]', untyped Number, 8081)
			.parse(Node.process.argv);
  
		
		var WebSocketClient = Node.require('websocket').client;
		var client :WebSocketClient = untyped __js__("new WebSocketClient()");
		
		Log.info("client" + Node.stringify(client));
		
		client.on('connectFailed', function(error) {
			Log.error('Connect Error: ' + error.toString());
		});
		
		client.on('connect', function(connection :WebSocketConnection) {
			Log.info('WebSocket client connected');
			connection.on('error', function(error) {
				Log.error("Connection Error: " + error.toString());
			});
			connection.on('close', function() {
				Log.warn('echo-protocol Connection Closed');
			});
			connection.on('message', function(message :WebSocketMessage) {
				if (message.type == 'utf8') {
					Log.info("Received: '" + message.utf8Data + "'");
				}
			});
		
			function sendNumber() {
				if (connection.connected) {
					var number = Math.round(Math.random() * 0xFFFFFF);
					connection.sendUTF(Std.string(number));
					Node.setTimeout(sendNumber, 1000);
				}
			}
			sendNumber();
		});
		
		Log.info("Connecting to " + 'ws://localhost:' + program.websocketport + '/, echo-protocol');
		client.connect('ws://localhost:' + program.websocketport + '/', ['echo-protocol']);	
	}
}
