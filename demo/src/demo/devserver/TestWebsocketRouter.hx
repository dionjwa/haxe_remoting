package demo.devserver;

import js.Node;

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
			.option('-w, --websocketport <websocketport>', 'specify the port [8000]', untyped Number, 8000)
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
		
		var router = new WebsocketRouter(server);
		
		// router.registerHandler(Message, function(msg :Message) {
		// 	Log.warn("Got message: " + msg);
			
		// 	var newMsg = new TestMessageType1();
		// 	newMsg.fieldX = Std.int(Math.random() * 1000);
		// 	router.sendMessage(newMsg);
		// });
		
		router.registerHandler(TestMessageType1, function(msg :TestMessageType1) {
			Log.warn("Got TestMessageType1: " + msg);
			
			// var newMsg = new TestMessageType1(msg.originId);
			// newMsg.fieldX = Std.int(Math.random() * 1000);
			var clientIds = router.getClientIds();
			trace('clientIds=' + clientIds);
			clientIds.remove(msg.originId);
			trace("Sending to " + clientIds);
			router.sendMessage(msg, clientIds);
		});
		
		
		
	}
}
