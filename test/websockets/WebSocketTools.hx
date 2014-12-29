package websockets;

import js.Node;
import js.node.WebSocketServer;

class WebSocketTools
{
	public static function buildWebSocketServer(port :Int, cb :WebSocketServer->Void)
	{
		// Log.info("creating WebSocketServer:" + port);
		var server = Node.http.createServer(function (req :NodeHttpServerReq, res :NodeHttpServerResp) {
			// Log.info(Date.now() + ' Received request for ' + req.url);
			res.writeHead(404);
			res.end();
		});

		var serverConfig :WebSocketServerConfig = {httpServer:server, autoAcceptConnections:false};
		var wsServer = new WebSocketServer(serverConfig);

		server.listen(port, 'localhost', null, function(ignored) {
			// Log.info(Date.now() + ' Websocket server running at http://localhost:' + port);
			// Log.info('RUNNING WebSocketServer at http://localhost:' + port);
			untyped wsServer.port = port;
			cb(wsServer);
		});
	}

	public static function closeWebSocketServer(server :WebSocketServer, cb :Void->Void)
	{
		var port :Int = untyped server.port;
		// Log.info("closing WebSocketServer:" + port);
		var httpServer :NodeHttpServer = untyped server.config.httpServer;
		server.shutDown();
		httpServer.close(function() {
			// Log.info("SHUTDOWN: WebSocketServer:" + port);
			cb();
		});
	}
}