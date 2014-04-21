package demo.devserver;

import js.Node;
import js.node.WebSocketServer;

using Lambda;

class TestWebsocketServer
{
	public static function main()
	{
		//https://github.com/visionmedia/commander.js
		var program :Dynamic= Node.require('commander');
		program
			.version('0.0.1')
			.option('-w, --websocketport <websocketport>', 'specify the port [8081]', untyped Number, 8081)
			.parse(Node.process.argv);
			
		var http :NodeHttp = Node.require('http');
		var server = http.createServer(function (req :NodeHttpServerReq, res :NodeHttpServerResp) {
			Log.info(Date.now() + ' Received request for ' + req.url);
			res.writeHead(404);
			res.end();
		});
			
		server.listen(program.websocketport, 'localhost', function() {
			Log.info(Date.now() + ' Websocket server running at http://localhost:' + program.websocketport);
		});
		
		
		var WebSocketServer = Node.require('websocket').server;
		var serverConfig :WebSocketServerConfig = {httpServer:server, autoAcceptConnections:false};
		var wsServer :WebSocketServer = untyped __js__("new WebSocketServer()");
		wsServer.on('connectFailed', function(error) {
			Log.error('Connect Error: ' + error.toString());
		});
		
		var requestAllowed = function (request :WebSocketRequest) :Bool {
		  // put logic here to detect whether the specified origin is allowed.
		  return request.requestedProtocols.indexOf('echo-protocol') > -1;
		}
		
		wsServer.on('request', function(request :WebSocketRequest) {
			if (!requestAllowed(request)) {
			  // Make sure we only accept requests from an allowed origin
			  request.reject(0, "No matching protocols");
			  // Log.warn(Date.now() + ' Connection from origin ' + request.origin + ' rejected.');
			  Log.warn(Date.now() + ' Connection from origin ' + request.origin + ' rejected. Request protocols: ' + request.requestedProtocols);
			  return;
			}
			
			
			Log.info("request.requestedProtocols: " + request.requestedProtocols);
			
			var connection = request.accept('echo-protocol', request.origin);
			Log.info(Date.now() + ' Connection accepted.');
			connection.on('message', function(message :WebSocketMessage) {
				if (message.type == 'utf8') {
					Log.info('Received Message: ' + message.utf8Data);
					connection.sendUTF(message.utf8Data);
				}
				else if (message.type == 'binary') {
					Log.info('Received Binary Message of ' + message.binaryData.length + ' bytes');
					connection.sendBytes(message.binaryData);
				}
			});
			connection.on('close', function(reasonCode, description) {
				Log.info(Date.now() + ' Peer ' + connection.remoteAddress + ' disconnected.');
			});
			connection.on('error', function(error) {
				Log.error(Date.now() + ' Error: ' + error);
			});
		});
		
		wsServer.mount(serverConfig);
	}
}
