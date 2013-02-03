package transition9.websockets;

import haxe.Serializer;
import haxe.Unserializer;

import flambe.util.SignalConnection;
import flambe.util.Signal1;
import flambe.util.Assert;

#if nodejs
import js.Node;
import js.node.WebSocketNode;
#else
	#if !html5
	#error
	#end
#end

class WebsocketClient extends WebsocketMessageHandler
{
	public var clientId (default, null) :String;
	public var connected (default, null) :Signal1<WebsocketClient>;
	public var disconnected (default, null) :Signal1<WebsocketClient>;
	
	var _messageSignal :Signal1<Dynamic>;
	var _ws_address :String;
	#if nodejs
	var _connection :WebSocketConnection;
	var _client :js.node.WebSocketNode.WebSocketClient;
	#else
	#end
	
	public function new (ws_address :String, ?clientId :String)
	
	{
		super();
		this.connected = new Signal1();
		this.disconnected = new Signal1();
		this.clientId = clientId;
		_ws_address = ws_address;
		#if nodejs
		var WebSocketClient = Node.require('websocket').client;
		var clientConfig :WebSocketClientConfig = {};
		_client = untyped __js__("new WebSocketClient([clientConfig])");
		connect();
		#else
		#end
		_messageSignal = new Signal1();
	}
	
	override public function sendMessage (msg :Dynamic, ?clientIds :Array<String> = null) :Void
	{
		Assert.that(_connection != null);
		var serializedMessage :String = Serializer.run(msg);
		_connection.sendUTF(serializedMessage);
	}
	
	function connect() :Void
	{
		#if nodejs
		Log.info("Attempting to connect to " + _ws_address);
		_client.addListener('connectFailed', onConnectFailed);
		_client.addListener('connect', onConnect);
		_client.connect(_ws_address, [Constants.HAXE_PROTOCOL]);
		#end
	}
	
	function onError (err :Dynamic) :Void
	{
		Log.warn("Websocket closed");
	}
	
	function onClose () :Void
	{
		Log.warn("Websocket closed");
		//Detach listeners?
		_connection.removeListener('error', onError);
		_connection.removeListener('message', onMessage);
		_connection = null;
		disconnected.emit(this);
	}
	
	#if nodejs
	function onConnect (connection :WebSocketConnection) :Void
	{
		Log.info("Websocket connected to " + _ws_address);
		_connection = connection;
		_connection.addListener('error', onError);
		_connection.addListener('message', onMessage);
		_connection.once('close', onClose);
		Log.info("Sending client registration (clientId=" + clientId + ")");
		_connection.sendUTF(Constants.REGISTER_CLIENT + clientId);
		// sendMessage(new MessageRegisterClient(clientId));
		connected.emit(this);
	}
	#else
	#end
	
	function onConnectFailed (error :Dynamic) :Void
	{
		Log.error("Websocket connection to " + _ws_address + " failed: " + error);
	}

}
