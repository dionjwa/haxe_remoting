package t9.websockets;


#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
#end

import flambe.util.SignalConnection;
import flambe.util.Signal1;
import flambe.util.Assert;

import haxe.Serializer;
import haxe.Unserializer;

import t9.websockets.Messages;

using StringTools;

#if !(macro || js || nodejs)
	#error
#end

#if nodejs
	#if !macro
		import js.Node;
		import js.node.WebSocketServer;
	#else
		typedef WebSocketConnection = {}
	#end
#end

class WebsocketClient
{
	public var clientId (default, null) :String;
	public var connected (default, null) :Signal1<WebsocketClient>;
	public var disconnected (default, null) :Signal1<WebsocketClient>;

	var _messageSignal :Signal1<Dynamic>;
	var _ws_address :String;
	#if ((nodejs || nodejs_std) && !macro)
	var _connection :WebSocketConnection;
	var _client :js.node.WebSocketServer.WebSocketClient;
	#elseif js
	var _connection :js.html.WebSocket;
	#end

	var _messageSignals :Map<String, Signal1<Dynamic>>;

	public function new (ws_address :String, ?clientId :String)
	{
		_messageSignals = new Map<String, Signal1<Dynamic>>();
		this.connected = new Signal1();
		this.disconnected = new Signal1();
		this.clientId = clientId;
		_ws_address = ws_address;
		#if !macro
			#if (nodejs || nodejs_std)
			var WebSocketClient = Node.require('websocket').client;
			var clientConfig :WebSocketClientConfig = {};
			_client = untyped __js__("new WebSocketClient([clientConfig])");
			connect();
			#else
			Log.info("New WebSocket", ["url", _ws_address, "protocols", Constants.WEBSOCKET_PROTOCOL]);
			throw "Check arguments, some are missing";
			_connection = new js.html.WebSocket(_ws_address);//, Constants.WEBSOCKET_PROTOCOL);
			_connection.onopen = onConnect;
			#end
		#end
		_messageSignal = new Signal1();
	}

	public function registerClient (clientId :String) :Void
	{
		#if !macro
		if (_connection != null) {
			if (clientId != null) {
				this.clientId = clientId;
				Log.info("Sending client registration (clientId=" + clientId + ")");
				#if (nodejs || nodejs_std)
				_connection.sendUTF(Constants.PREFIX_REGISTER_CLIENT + clientId);
				#elseif js
				_connection.send(Constants.PREFIX_REGISTER_CLIENT + clientId);
				#end
			} else {
				Log.error("Cannot register client, clientId==null");
			}
		} else {
			Log.error("Cannot register client, _connection==null");
		}
		#end
	}

	public function registerMessageHandlerById (messageId :String, handler :Dynamic->Void) :SignalConnection
	{
		// #if !macro
		// Log.info("registerMessageHandler", ["messageId", messageId]);
		// #end
		if (!_messageSignals.exists(messageId)) {
			_messageSignals.set(messageId, new Signal1<Dynamic->Void>());
		}
		return _messageSignals.get(messageId).connect(handler);
	}

	public function registerMessageHandlerByClass <T> (cls :Class<T>, handler :T->Void) :SignalConnection
	{
		return registerMessageHandlerById(Type.getClassName(cls), handler);
	}

	//Rewrites into registerMessageHandlerById(Type.getClassName(T), cb);
	// macro public function registerMessageHandler <T> (self :Expr, cb :ExprRequire<T->Void>)
	macro
	public function registerMessageHandler <T> (self :Expr, cb :Expr)
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

	public function sendJson (obj :Dynamic) :Void
	{
		#if !macro
			sendMessage(Constants.PREFIX_HAXE_JSON + haxe.Json.stringify(obj));
		#end
	}

	public function sendObj (obj :Dynamic) :Void
	{
		sendMessage(Constants.PREFIX_HAXE_OBJECT + Serializer.run(obj));
	}

	public function sendMessage (serializedMessage :String) :Void
	{
		#if !macro
			Assert.that(_connection != null, "_connection != null");
			#if (nodejs || nodejs_std)
			_connection.sendUTF(serializedMessage);
			#elseif js
			_connection.send(serializedMessage);
			#end
		#end
	}

	function connect() :Void
	{
		#if ((nodejs || nodejs_std) && !macro)
		Log.info("Attempting to connect to " + _ws_address);
		_client.addListener('connectFailed', onConnectFailed);
		_client.addListener('connect', onConnect);
		_client.connect(_ws_address, [Constants.WEBSOCKET_PROTOCOL]);
		#end
	}

	function onError (err :Dynamic) :Void
	{
		#if !macro
		Log.warn("Websocket closed");
		#end
	}

	#if (nodejs || nodejs_std || macro)
	function onClose () :Void
	#else
	function onClose (e :js.html.Event) :Void
	#end
	{
		#if !macro
			Log.warn("Websocket closed");
			#if (nodejs || nodejs_std)
			//Detach listeners?
			_connection.removeListener('error', onError);
			_connection.removeListener('message', onMessage);
			#elseif js
			_connection.onerror = null;
			_connection.onmessage = null;
			#end
			_connection = null;
			disconnected.emit(this);
		#end
	}

	#if (nodejs || nodejs_std)
	function onConnect (connection :WebSocketConnection) :Void
	{
		#if !macro
			Log.info("Websocket connected to " + _ws_address);
			_connection = connection;
			_connection.addListener('error', onError);
			_connection.addListener('message', onMessage);
			_connection.once('close', onClose);
			if (clientId != null) {
				registerClient(clientId);
			}
			connected.emit(this);
		#end
	}
	#elseif js
	function onConnect (e :js.html.Event) :Void
	{
		#if !macro
		Log.info("Websocket connected to " + _ws_address);

		_connection.onerror = onError;
		_connection.onclose = onClose;
		_connection.onmessage = onMessage;
		if (clientId != null) {
			registerClient(clientId);
		}
		connected.emit(this);

		#end
	}
	#else
	function onConnect () :Void {}
	#end

	function onConnectFailed (error :Dynamic) :Void
	{
		#if !macro
		Log.error("Websocket connection to " + _ws_address + " failed: " + error);
		#end
	}

	#if macro
	function onMessage (message :Dynamic) :Void
	{}
	#elseif (nodejs || nodejs_std)
	function onMessage (message :WebSocketMessage) :Void
	{
		#if !macro
			if (message.type == 'utf8') {
				if (message.utf8Data.startsWith(Constants.PREFIX_HAXE_JSON)) {
					var unserializedMessage :JsonMessage = Messages.decodeJsonMessage(message.utf8Data);
					if (unserializedMessage != null && unserializedMessage.id != null && _messageSignals.exists(unserializedMessage.id)) {
						_messageSignals.get(unserializedMessage.id).emit(unserializedMessage);
					} else {
						Log.warn("Json message not handled (missing id field?): " + message.utf8Data);
						Log.warn("Message types handled: " + _messageSignals.keys());
					}
				} else if (message.utf8Data.startsWith(Constants.PREFIX_HAXE_OBJECT)) {
					var unserializedMessage :Dynamic = Messages.decodeHaxeMessage(message.utf8Data);
					if (unserializedMessage != null) {
						var messageId :String = Type.getClassName(Type.getClass(unserializedMessage));
						if (_messageSignals.exists(messageId)) {
							_messageSignals.get(messageId).emit(unserializedMessage);
						} else {
							Log.warn("Message not handled: " + messageId);
							Log.warn("Message types handled: " + _messageSignals.keys());
						}
					}
				} else {
					//Untyped message
					Log.warn("Unhandled message: " + message.utf8Data);
				}
			}
			else if (message.type == 'binary') {
				Log.info('Received Binary Message of ' + message.binaryData.length + ' bytes');
			}
		#end
	}
	#elseif js
	function onMessage (e :js.html.Event) :Dynamic
	{
		var msg :{data:String} = cast e;
		#if !macro
		Log.info("onMessage.data: " + msg.data);
		#end

		var msgData = msg.data;
		if (msgData.startsWith(Constants.PREFIX_HAXE_JSON)) {
			var unserializedMessage :JsonMessage = Messages.decodeJsonMessage(msgData);
			if (unserializedMessage != null && unserializedMessage.id != null && _messageSignals.exists(unserializedMessage.id)) {
				_messageSignals.get(unserializedMessage.id).emit(unserializedMessage);
			} else {
				Log.warn("Json message not handled (missing id field?): " + msgData);
				Log.warn("Message types handled: " + _messageSignals.keys());
			}
		} else if (msgData.startsWith(Constants.PREFIX_HAXE_OBJECT)) {
			var unserializedMessage :Dynamic = Messages.decodeHaxeMessage(msgData);
			if (unserializedMessage != null) {
				var messageId :String = Type.getClassName(Type.getClass(unserializedMessage));
				if (_messageSignals.exists(messageId)) {
					_messageSignals.get(messageId).emit(unserializedMessage);
				} else {
					Log.warn("Message not handled: " + messageId);
					Log.warn("Message types handled: " + _messageSignals.keys());
				}
			}
		} else {
			//Untyped message, unhandled
			#if !macro
			Log.warn("Message not handled: " + msgData);
			Log.warn("Message types handled: " + _messageSignals.keys());
			#end
		}

		return msgData;

	}
	#end

}
