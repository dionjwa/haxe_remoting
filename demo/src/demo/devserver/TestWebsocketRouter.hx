package demo.devserver;

import js.Node;
import js.node.Connect;

import transition9.websockets.WebsocketRouter;

class TestWebsocketRouter
{
	public static function main () :Void
	{
		//Compile the client too 
		TestWebsocketRouterClient;
		
		//https://github.com/visionmedia/commander.js
		var program :Dynamic= Node.require('commander');
		program
			.version('0.0.1')
			.option('-w, --websocketport <websocketport>', 'specify the port [8001]', untyped Number, 8001)
			.parse(Node.process.argv);
			
		var http :NodeHttp = Node.require('http');
		var server = http.createServer(function (req :NodeHttpServerReq, res :NodeHttpServerResp) {
			Log.info(Date.now() + ' Received request for ' + req.url);
			res.writeHead(404);
			res.end();
		});
		
		
		//http://www.senchalabs.org/connect/
		// var connect :Connect = Node.require('connect');
		// var server = connect.createServer(
		// 	connect.logger('dev')
		// );
		
		
		
		// server.listen(program.websocketport, 'localhost');
		server.listen(program.websocketport, 'localhost', function() {
			Log.info(Date.now() + ' Websocket server running at http://localhost:' + program.websocketport);
		});
		
		var router = new WebsocketRouter(server);
		
		router.registerMessageHandler(function(msg :demo.devserver.TestMessageType1, conn :RouterSocketConnection) {
			Log.warn("Got TestMessageType1: " + msg);
			var clientIds = router.getClientIds();
			trace('clientIds=' + clientIds);
			clientIds.remove(msg.originId);
			trace("Sending to " + clientIds);
			router.sendObj(msg, clientIds);
		});
		
	}
}
