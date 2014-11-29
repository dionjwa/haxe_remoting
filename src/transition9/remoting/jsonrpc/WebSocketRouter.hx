package transition9.remoting.jsonrpc;

import haxe.Json;

#if !macro
	#if nodejs
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

/**
  * 
  */
class WebSocketRouter
{
	#if !macro
	var _websocketServer :WebSocketServer;
	#end

	var _context :Context;

	#if !macro
	public function new (websocketServer :WebSocketServer)
	{
		_websocketServer = websocketServer;
		// _websocketServer = new WebSocketServer({httpServer:httpServer, autoAcceptConnections:false});
		_websocketServer.on('connectFailed', onConnectFailed);
		_websocketServer.on('request', onWebsocketRequest);
	}
	#else
	public function new (ignored :Dynamic) {}
	#end

	public function setContext(context :Context) :WebSocketRouter
	{
		_context = context;
		return this;
	}

	public function dispose()
	{
		if (_context != null) {
			_context.dispose();
		}
		Log.info("WebSocketRouter._websocketServer.closeAllConnections()");
		_websocketServer.shutDown();
		_websocketServer.removeListener('connectFailed', onConnectFailed);
		_websocketServer.removeListener('request', onWebsocketRequest);
		_websocketServer = null;
	}

	#if !macro
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
			// if (protocol == Constants.WEBSOCKET_PROTOCOL) {
			// 	allowed = true;
			// 	break;
			// }
		}

		if (!allowed) {
			// Make sure we only accept requests from an allowed origin
			Log.warn(Date.now() + ' Connection from origin ' + request.origin + ' rejected. Request protocols: ' + request.requestedProtocols);
		}
		return allowed;
	}

	function onWebsocketRequest (request :WebSocketRequest) :Void
	{
		Log.info("request.requestedProtocols: " + request.requestedProtocols);

		if (!isRequestAllowed(request)) {
			request.reject(0, "No matching protocols");
			return;
		}

		var connection : RouterSocketConnection = cast request.accept(null, request.origin);
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
	}

	function onConnectFailed (error :Dynamic) :Void
	{
		Log.error("WebsocketRouter connection failed: " + error);
	}

	function onClientMessage (connection :RouterSocketConnection, message :WebSocketMessage) :Void
	{
		Log.info("onMessage: " + message);
		if (message.type == 'utf8') {
			try {
				var rpcRequest = Json.parse(message.utf8Data);
				if (_context != null) {
					Log.info("Context handling request");
					try {
						_context.handleRequest(connection, rpcRequest);
					} catch (e :Dynamic) {
						Log.error("Error on context.handleRequest: " + e);
					}
				} else {
					Log.info("No context to handle the message");
				}
			} catch (e :Dynamic) {
				Log.error("Error parsing message: " + message);
			}
		}
		else if (message.type == 'binary') {
			Log.error('Received Binary Message of ' + message.binaryData.length + ' bytes');
		} else {
			Log.error("Unhandled socket message: " + message);
		}
	}

	function onClientConnectionClose (connection :RouterSocketConnection, reasonCode :Int, description :String) :Void
	{
		Log.info(Date.now() + ' Peer ' + connection.remoteAddress + ' disconnected.');
	}

	function onClientConnectionError (connection :RouterSocketConnection, error :Dynamic) :Void
	{
		// Log.error(Date.now() + ' Peer ' + connection.remoteAddress + ' error: ' + error);
		Log.error(' Peer ' + connection.remoteAddress + ' error: ' + error);
	}
	#end
}
