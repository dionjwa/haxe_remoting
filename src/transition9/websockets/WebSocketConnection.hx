package transition9.websockets;

#if nodejs
	#if !macro
		import js.Node;
		import js.node.WebSocket;
	#end
#elseif cocos2dx
	import cc.Cocos2dx;
#elseif js
	import js.html.WebSocket;
#end

/**
 * This will reconnect if dropped.
 */
class WebSocketConnection
{
	public var onerror :Dynamic->Void;
	public var onopen :Dynamic->Void;
	public var onmessage :Dynamic->Void;
	public var onclose :Dynamic->Void;

	public function new(url :String, ?keepAliveMilliseconds :Int = 25000)
	{
		_url = url;
		_keepAliveMilliseconds = keepAliveMilliseconds;
        connect();
	}

	public function send(data) :Bool
	{
		if (_socket != null && _socket.readyState == 1) {
            _socket.send(data);
            untyped clearInterval(_keepAliveTimoutId);
        	_keepAliveTimoutId = 0;
        	return true;
        } else {
        	trace("Cannot send message, websocket not ready");
        	return false;
        }
	}

	public function dispose()
	{
		if (_socket != null) {
			_socket.close();
			_socket.onerror = null;
            _socket.onopen = null;
            _socket.onmessage = null;
            _socket.onclose = null;
            _socket = null;
		}
	}

	function connect()
	{
		#if nodejs
			_socket = new WebSocket(this._url);
		#else
			untyped __js__('var WebSocket = WebSocket || window.WebSocket || window.MozWebSocket');
			_socket = untyped __js__('new WebSocket(this._url, [])');
		#end

		_socket.onerror = function (event) {
            if (this.onerror != null) {
            	this.onerror(event);
            }
        };
        _socket.onopen = function (event) {
            if (this.onopen != null) {
            	this.onopen(event);
            }
            restartTimeoutTimer();
        };
        // _socket.onmessage = function (event :MessageEvent) {
        _socket.onmessage = function (event) {
            Log.info("onmessage " + untyped event.data);
            onmessage(event);
        };

        _socket.onclose = function (event) {
        	untyped clearInterval(_keepAliveTimoutId);
        	_keepAliveTimoutId = 0;
            Log.info("onclose " + untyped JSON.stringify(event));
            Log.info("...reconnecting");
            _socket.onerror = null;
            _socket.onopen = null;
            _socket.onmessage = null;
            _socket.onclose = null;
            _socket = null;
            untyped setTimout(function() {
            	connect();
        	}, 1000);//Hardcode retry timer for now
        };
	}

	function restartTimeoutTimer()
	{
		if (_keepAliveTimoutId != 0) {
			untyped clearInterval(_keepAliveTimoutId);
			untyped _keepAliveTimoutId = setInterval(function() {
                if (_socket.readyState == 1) {
                	#if nodejs
                    	_socket.ping("hey");
                    #else
                    	_socket.send("keep_alive");
                    #end
                }
            }, _keepAliveMilliseconds);
		}
	}

	var _socket :WebSocket;
	var _url :String;
	var _keepAliveMilliseconds :Int;
	var _keepAliveTimoutId :Int;
}