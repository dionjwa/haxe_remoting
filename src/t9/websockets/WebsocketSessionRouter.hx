package t9.websockets;

#if !macro
	#if (nodejs || nodejs_std)
	import js.node.WebSocketServer;
	import js.Node;
	#end
#else
	import haxe.macro.Expr;
	import haxe.macro.Context;
#end

using StringTools;
using Lambda;

typedef RouterSocketConnection = { #if !macro >WebSocketConnection, #end
	var clientId :String;
}

class WebsocketSessionRouter
{
	public function new(httpServer :NodeHttpServer)
	{
		_websocketServer = new WebSocketServer({httpServer:httpServer, autoAcceptConnections:false});
		_websocketServer.on('connectFailed', onConnectFailed);
		_websocketServer.on('request', onWebsocketRequest);
	}

	function isRequestAllowed (request :WebSocketRequest) :Bool
	{
		Log.info("request: " + request.httpRequest);

		#if debug
		//Debug builds accept all connections
		return true;
		#end

		// put logic here to detect whether the specified origin is allowed.
		// var allowed = false;
		//For now, accept all requests
		var allowed = true;

		for (protocol in request.requestedProtocols) {
			if (protocol == Constants.WEBSOCKET_PROTOCOL) {
				allowed = true;
				break;
			}
		}

		if (!allowed) {
			// Make sure we only accept requests from an allowed origin
			request.reject(0, "No matching protocols");
			Log.warn(Date.now() + ' Connection from origin ' + request.origin + ' rejected. Request protocols: ' + request.requestedProtocols);
		}
		return allowed;
	}
	function onWebsocketRequest (request :WebSocketRequest) :Void
	{
		Log.info("request.requestedProtocols: " + request.requestedProtocols);

		if (!isRequestAllowed(request)) {
			request.reject();//Status for rejection?
			return;
		}

		var connection : RouterSocketConnection = cast request.accept(Constants.WEBSOCKET_PROTOCOL, request.origin);
		connection.clientId = null;//We don't know about this client yet.

		Log.info(Date.now() + ' Connection accepted.');
		connection.on('message', function(message :WebSocketMessage) {
			onClientMessage(connection, message);
		});

		connection.once('close', function(reasonCode, description) {
			onClientConnectionClose(connection, reasonCode, description);
		});

		connection.on('error', function(error) {
			onClientConnectionError(connection, error);
		});

		_unMappedConnections.push(connection);

		clientConnected.emit(connection);

		// trace('_unMappedConnections=' + _unMappedConnections);
	}

	function onConnectFailed (error :Dynamic) :Void
	{
		Log.error("WebsocketRouter connection failed: " + error);
	}


	var _websocketServer :WebSocketServer;
}