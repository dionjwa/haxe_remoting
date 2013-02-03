package transition9.websockets;

import flambe.util.Assert;

import haxe.Serializer;

import haxe.Unserializer;

import js.Node;

import js.node.WebSocketNode;

using StringTools;

typedef RouterSocketConnection = {>WebSocketConnection,
	var clientId :String;
}

/**
  * 
  */
class WebsocketRouter extends WebsocketMessageHandler
{
	var _mappedConnections :Hash<RouterSocketConnection>;
	var _unMappedConnections :Array<RouterSocketConnection>;
	var _websocketServer :WebSocketServer;
	
	public function new (httpServer :NodeHttpServer)
	{
		super();
		_mappedConnections = new Hash();
		_unMappedConnections = [];
		
		var WebSocketServer = Node.require('websocket').server;
		var serverConfig :WebSocketServerConfig = {httpServer:httpServer, autoAcceptConnections:false};
		_websocketServer = untyped __js__("new WebSocketServer()");
		_websocketServer.on('connectFailed', onConnectFailed);
		_websocketServer.on('request', onWebsocketRequest);
		_websocketServer.mount(serverConfig);
	}
	
	public function getClientIds () :Array<String>
	{
		var clientIds :Array<String> = [];
		for (clientId in _mappedConnections.keys()) {
			clientIds.push(clientId);
		}
		return clientIds;
	}
	
	override public function sendMessage (msg :Dynamic, ?clientIds :Array<String> = null) :Void
	{
		var serializedMessage = Serializer.run(msg);
		if (clientIds == null) {
			//Broadcast
			for (connection in _mappedConnections) {
				connection.sendUTF(serializedMessage);
			}
			for (connection in _unMappedConnections) {
				connection.sendUTF(serializedMessage);
			}
			
		} else {
			if (clientIds.length > 0) {
				for (clientId in clientIds) {
					if (_mappedConnections.exists(clientId)) {
						_mappedConnections.get(clientId).sendUTF(serializedMessage);
					} else {
						Log.warn("sendMessage, no connection for clientId=" + clientId);
					}
				}
			}
		}
	}
	
	function isRequestAllowed (request :WebSocketRequest) :Bool
	{
		Log.info("request: " + request.httpRequest);
		// put logic here to detect whether the specified origin is allowed.
		// var allowed = false;
		//For now, accept all requests
		var allowed = true;
		
		for (protocol in request.requestedProtocols) {
			if (protocol == Constants.HAXE_PROTOCOL) {
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
			return;
		}
		
		var connection : RouterSocketConnection = cast request.accept(Constants.HAXE_PROTOCOL, request.origin);
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
		if (message.type == 'utf8') {
			
			if (message.utf8Data.startsWith(Constants.REGISTER_CLIENT)) {
				var clientId = message.utf8Data.substr(Constants.REGISTER_CLIENT.length);
				Log.info("Registering " + clientId);
				_mappedConnections.set(clientId, connection);
				_unMappedConnections.remove(connection);
			} else {
				onMessage(message);
			}
		}
		else if (message.type == 'binary') {
			Log.info('Received Binary Message of ' + message.binaryData.length + ' bytes');
		}
	}
	
	function onClientConnectionClose (connection :RouterSocketConnection, reasonCode :Int, description :String) :Void
	{
		Log.info(Date.now() + ' Peer ' + connection.remoteAddress + ' disconnected.');
	}
	
	function onClientConnectionError (connection :RouterSocketConnection, error :Dynamic) :Void
	{
		Log.error(Date.now() + ' Peer ' + connection.remoteAddress + ' error: ' + error);
	}
}
