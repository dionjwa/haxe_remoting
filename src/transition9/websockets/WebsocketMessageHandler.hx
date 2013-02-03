package transition9.websockets;

import haxe.Serializer;
import haxe.Unserializer;

import flambe.util.Assert;
import flambe.util.Signal1;
import flambe.util.SignalConnection;

#if nodejs
import js.node.WebSocketNode;
#else
	#if !html5
	#error
	#end
#end

class WebsocketMessageHandler
{
	var _messageSignals :Hash<Signal1<Dynamic>>;
	
	public function new ()
	{
		_messageSignals = new Hash<Signal1<Dynamic>>();
	}
	
	public function registerHandler (messageType :Class<Dynamic>, cb :Dynamic->Void) :SignalConnection
	{
		// var messageId :String = Reflect.field(messageType, "ID");
		var messageId :String = Type.getClassName(messageType);
		Assert.that(messageId != null);
		if (!_messageSignals.exists(messageId)) {
			_messageSignals.set(messageId, new Signal1<Dynamic>());
		}
		return _messageSignals.get(messageId).connect(cb);
	}
	
	public function sendMessage (msg :Dynamic, ?clientIds :Array<String> = null) :Void
	{
		throw "Override me";
	}
	
	function onMessage (msg :Dynamic) :Dynamic
	{
		// Log.info("onMessage: " + msg);
		if (msg.type == 'utf8') {
			var unserializedMessage :Dynamic = Unserializer.run(msg.utf8Data);
			var messageId :String = Type.getClassName(Type.getClass(unserializedMessage));
			if (_messageSignals.exists(messageId)) {
				_messageSignals.get(messageId).emit(unserializedMessage);
			} else {
				Log.warn("Message not handled: " + messageId);
			}
			return unserializedMessage;
		} else {
			return null;
		}
	}
}
