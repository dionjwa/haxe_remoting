package t9.remoting.jsonrpc;

import haxe.Json;
import haxe.remoting.JsonRPC;

import t9.websockets.WebSocketConnection;

class ClientConnectionWebSocket
	implements ConnectionClient
{
	public function new(websocket :WebSocketConnection)
	{
		_websocket = websocket;
		_requestQueue = [];
		_listeners = [];
		_disposeCalls = [];
		_disposeCalls.push(websocket.registerOnMessage(onMessage));
	}

	public function addResponseListener(onResponse :ResponseDef->Void) : {dispose:Void->Void}
	{
		var length = _listeners.length;
		_listeners.push(onResponse);
		return {dispose:function() {
			_listeners[length] = null;
		}};
	}

	public function sendRequest(request :RequestDef) :Void
	{
		// trace('ClientConnectionWebSocket.sendRequest _requestQueue=$_requestQueue');
		//Attempt to send the queue, if any
		if (_requestQueue.length > 0) {
			var currentRequest = _requestQueue.shift();
			while (currentRequest != null) {
				// Log.info("stuff???");
				// Log.info("attempting to send via websocket...");
				if (_websocket.send(Json.stringify(currentRequest))) {
					currentRequest = _requestQueue.shift();
				} else {
					_requestQueue.unshift(currentRequest);
					break;
				}
			}
		}
		if (request != null) {
			// Log.info("attempting to send via websocket..." + Json.stringify(request));
			if (!_websocket.send(Json.stringify(request))) {
				_requestQueue.push(request);
			}
		}
	}

	public function sendRequests(requests :Array<RequestDef>) :Void
	{
		_requestQueue = _requestQueue.concat(requests);
		sendRequest(null);
	}

	public function dispose()
	{
		for (disposable in _disposeCalls) {
			disposable.dispose();
		}
		_websocket.dispose();
		_websocket = null;
		_listeners = null;
		_requestQueue = null;
		_disposeCalls = null;
	}

	function onMessage(event)
	{
		var s :String = untyped event.data;
		try {
			var result :ResponseDef = Json.parse(s);
			var i = 0;
			while (i < _listeners.length) {
				if (_listeners[i] != null) {
					try {
						_listeners[i](result);
					} catch (e :Dynamic) {
						Log.error('Error with listener on message=$result err=$e');
					}
				}
				i++;
			}

		} catch(e :Dynamic) {
			Log.error("Failed to parse message'" + s + "'");
		}
	}

	var _websocket :WebSocketConnection;
	var _listeners :Array<ResponseDef->Void>;
	var _requestQueue :Array<RequestDef>;//When the socket is down
	var _disposeCalls :Array<{dispose:Void->Void}>;
}