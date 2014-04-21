package transition9.remoting.jsonrpc;

import haxe.Json;

import transition9.remoting.jsonrpc.RPC;
import transition9.websockets.WebSocketConnection;

class RPCConnectionWebsocket
	implements RPCConnection
{
	public var onResponse :ResponseDef->Void;

	public function new(websocket :WebSocketConnection)
	{
		_websocket = websocket;
		_requestQueue = [];
	}

	public function sendRequest(request :RequestDef) :Void
	{
		//Attempt to send the queue, if any
		if (_requestQueue.length > 0) {
			var currentRequest = _requestQueue.shift();
			while (currentRequest != null) {
				if (_websocket.send(Json.stringify(currentRequest))) {
					currentRequest = _requestQueue.shift();
				} else {
					_requestQueue.unshift(currentRequest);
					break;
				}
			}
		}
		if (request != null) {
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

	var _websocket :WebSocketConnection;
	var _requestQueue :Array<RequestDef>;//When the socket is down
}