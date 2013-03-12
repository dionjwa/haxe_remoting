package transition9.websockets;

import flambe.util.Assert;
import flambe.util.Signal2;
import flambe.util.Signal1;
import flambe.util.SignalConnection;

import haxe.Serializer;
import haxe.Unserializer;

import transition9.websockets.Messages;

#if !macro
	#if (nodejs || nodejs_std)
	import js.node.WebSocketNode;
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
class WebsocketRouter
{
	public var clientConnected (default, null):Signal1<RouterSocketConnection>;
	public var clientDisconnected (default, null):Signal1<RouterSocketConnection>;
	public var clientRegistered (default, null):Signal1<RouterSocketConnection>;
	
	
	#if haxe3
	var _messageSignals :Map<String, Signal2<Dynamic, RouterSocketConnection>>;
	var _mappedConnections :Map<String, RouterSocketConnection>;
	#else
	var _messageSignals :Hash<Signal2<Dynamic, RouterSocketConnection>>;
	var _mappedConnections :Hash<RouterSocketConnection>;
	#end
	
	var _unMappedConnections :Array<RouterSocketConnection>;
	#if !macro
	var _websocketServer :WebSocketServer;
	#end
	
	#if !macro
	public function new (httpServer :NodeHttpServer)
	{
		this.clientConnected = new Signal1<RouterSocketConnection>();
		this.clientDisconnected = new Signal1<RouterSocketConnection>();
		this.clientRegistered = new Signal1<RouterSocketConnection>();
		
		#if haxe3
		_messageSignals = new Map<String, Signal2<Dynamic, RouterSocketConnection>>();
		_mappedConnections = new Map();
		#else
		_messageSignals = new Hash<Signal2<Dynamic, RouterSocketConnection>>();
		_mappedConnections = new Hash();
		#end
		
		_unMappedConnections = [];
		var WebSocketServer = Node.require('websocket').server;
		var serverConfig :WebSocketServerConfig = {httpServer:httpServer, autoAcceptConnections:false};
		_websocketServer = untyped __js__("new WebSocketServer()");
		_websocketServer.on('connectFailed', onConnectFailed);
		_websocketServer.on('request', onWebsocketRequest);
		_websocketServer.mount(serverConfig);
		
		
	}
	#else
	public function new (ignored :Dynamic) {}
	#end
	
	public function getClientIds () :Array<String>
	{
		//This could be made more efficient.  Perhaps a set?
		var clientIds :Array<String> = [];
		for (clientId in _mappedConnections.keys()) {
			clientIds.push(clientId);
		}
		return clientIds;
	}
	
	public function sendJson (obj :Dynamic, ?clientIds :Array<String> = null) :Void
	{
		#if !macro
			sendMessage(Constants.PREFIX_HAXE_JSON + Node.stringify(obj), clientIds);
		#end
	}
	
	public function sendObj (obj :Dynamic, ?clientIds :Array<String> = null) :Void
	{
		sendMessage(Constants.PREFIX_HAXE_OBJECT + Serializer.run(obj), clientIds);
	}
	
	public function sendMessage (serializedMessage :String, ?clientIds :Array<String> = null) :Void
	{
		#if !macro
			Log.info("sendMessage", ["serializedMessage", serializedMessage, "clientIds", clientIds, "_mappedConnections.keys().size()", _mappedConnections.list().array().length, "_unMappedConnections.length", _unMappedConnections.length]);
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
		#end
	}
	
	public function registerMessageHandlerById (messageId :String, handler :Dynamic->RouterSocketConnection->Void) :SignalConnection
	{
		#if !macro
		Log.info("registerMessageHandler", ["messageId", messageId]);
		#end
		if (!_messageSignals.exists(messageId)) {
			var signal = new Signal2<Dynamic, RouterSocketConnection>();
			_messageSignals.set(messageId, signal);
		}
		return _messageSignals.get(messageId).connect(handler);
	}
	
	public function registerMessageHandlerByClass <T> (cls :Class<T>, handler :T->RouterSocketConnection->Void) :SignalConnection
	{
		return registerMessageHandlerById(Type.getClassName(cls), handler);
	}
	
	//Rewrites into registerMessageHandlerById(Type.getClassName(T), cb);
	#if haxe3
	macro
	public function registerMessageHandler <T> (self :Expr, cb :Expr)
	#else
	@:macro
	public function registerMessageHandler <T> (self :Expr, cb :ExprRequire<T->RouterSocketConnection->Void>)
	#end
	// public function registerMessageHandler <T> (self :Expr, cb :Expr)
	{
		switch(cb.expr) {
			case EFunction(_, f):
				var functionArg = f.args[0];
				switch(functionArg.type) {
					case TPath(typepath):
						// if (typepath.pack.length == 0) {
						// 	Context.warning(typepath.name + " argument to callback should be fully typed (include the full package name)", self.pos);
						// }
						return {
						    expr: ECall({
						        expr: EField(self, "registerMessageHandlerByClass"),
						        pos: self.pos
						    // }, [ {expr :EConst(Constant.CString(typepath.pack.concat([typepath.name]).join("."))), pos:self.pos}, cb ]),
						    }, [ {expr :EConst(Constant.CIdent(typepath.name)), pos:self.pos}, cb ]),
						    pos: self.pos
						};
					default:
						Context.error("Should not get here", self.pos);
						return {expr :EConst(Constant.CString("test")), pos:self.pos};
						//ignored
				}
			default: 
				Context.error("You must pass in a function callback", self.pos);
				return {expr :EConst(Constant.CString("test")), pos:self.pos};
		}
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
	
	function onClientMessage (connection :RouterSocketConnection, message :WebSocketMessage) :Void
	{
		Log.info("onMessage: " + message.utf8Data);
		if (message.type == 'utf8') {
			
			if (message.utf8Data.startsWith(Constants.PREFIX_REGISTER_CLIENT)) {
				var clientId = message.utf8Data.substr(Constants.PREFIX_REGISTER_CLIENT.length);
				Assert.that(clientId != null, "clientId != null");
				Assert.that(!_mappedConnections.exists(clientId) || _mappedConnections.get(clientId) == connection, "_mappedConnections.exists(clientId) && _mappedConnections.get(clientId) != connection");
				Log.info("Registering " + clientId);
				connection.clientId = clientId;
				_mappedConnections.set(clientId, connection);
				_unMappedConnections.remove(connection);
				clientRegistered.emit(connection);
			} else if (message.utf8Data.startsWith(Constants.PREFIX_HAXE_JSON)) {
				var unserializedMessage :JsonMessage = Messages.decodeJsonMessage(message.utf8Data);
				if (unserializedMessage != null && unserializedMessage.id != null && _messageSignals.exists(unserializedMessage.id)) {
					_messageSignals.get(unserializedMessage.id).emit(unserializedMessage, connection);
				} else {
					Log.warn("Json message not handled (missing id field?): " + message.utf8Data);
				}
			} else if (message.utf8Data.startsWith(Constants.PREFIX_HAXE_OBJECT)) {
				var unserializedMessage :Dynamic = Messages.decodeHaxeMessage(message.utf8Data);
				if (unserializedMessage != null) {
					var messageId :String = Type.getClassName(Type.getClass(unserializedMessage));
					if (_messageSignals.exists(messageId)) {
						_messageSignals.get(messageId).emit(unserializedMessage, connection);
					} else {
						Log.warn("Message not handled: " + messageId);
					}
				}
			} else {
				//Untyped message, unhandled
				onMessage(connection, message.utf8Data);
			}
		}
		else if (message.type == 'binary') {
			Log.info('Received Binary Message of ' + message.binaryData.length + ' bytes');
		}
	}
	
	function onClientConnectionClose (connection :RouterSocketConnection, reasonCode :Int, description :String) :Void
	{
		Log.info(Date.now() + ' Peer ' + connection.remoteAddress + ' disconnected.');
		_mappedConnections.remove(connection.clientId);
		_unMappedConnections.remove(connection);
		clientDisconnected.emit(connection);
	}
	
	function onClientConnectionError (connection :RouterSocketConnection, error :Dynamic) :Void
	{
		// Log.error(Date.now() + ' Peer ' + connection.remoteAddress + ' error: ' + error);
		Log.error(' Peer ' + connection.remoteAddress + ' error: ' + error);
	}
	
	//Override
	function onMessage (connection :RouterSocketConnection, msg :String) :Void
	{
		Log.error(' Peer ' + connection.remoteAddress + ' Unhandled message: ' + msg);
	}
	#end
}
