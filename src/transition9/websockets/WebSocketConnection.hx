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
	public function new(url :String, ?keepAliveMilliseconds :Int = 25000)
	{
        _onerror = [];
        _onopen = [];
        _onmessage = [];
        _onclose = [];
		_url = url;
		_keepAliveMilliseconds = keepAliveMilliseconds;
        _disposed = false;
        connect();
	}

    public function registerOnError(onError :Dynamic->Void) :{dispose:Void->Void}
    {
        _onerror.push(onError);
        var index = _onerror.length - 1;
        return {dispose:function() {
            Log.info("WebSocketConnection removing onError");
            _onerror[index] = null;
        }};
    }

    public function registerOnOpen(onOpen :Void->Void) :{dispose:Void->Void}
    {
        _onopen.push(onOpen);
        var index = _onopen.length - 1;
        return {dispose:function() {
            Log.info("WebSocketConnection removing onOpen");
            _onopen[index] = null;
        }};

        if (_socket != null && _socket.readyState == js.html.WebSocket.OPEN) {
            var i = 0;
            while (i < _onopen.length) {
                if (_onopen[i] != null) {
                    _onopen[i]();
                }
                i++;
            }
        }
    }

    public function registerOnMessage(onMessage :Dynamic->Void) :{dispose:Void->Void}
    {
        _onmessage.push(onMessage);
        var index = _onmessage.length - 1;
        return {dispose:function() {
            Log.info("WebSocketConnection removing onMessage");
            _onmessage[index] = null;
        }};
    }

    public function registerOnClose(onClose :Dynamic->Void) :{dispose:Void->Void}
    {
        _onclose.push(onClose);
        var index = _onclose.length - 1;
        return {dispose:function() {
            Log.info("WebSocketConnection removing onClose");
            _onclose[index] = null;
        }};
    }

	public function send(data) :Bool
	{
        Log.info('send _socket=${_socket != null} _socket.readyState=' + (_socket != null ? _socket.readyState : -1));
		if (_socket != null && _socket.readyState == 1) {
            Log.info('sending via ACTUAL socket: ' + data);
            _socket.send(data);
            Log.info('finished sending via ACTUAL socket: ');
            // restartTimeoutTimer();
        	return true;
        } else {
        	Log.warn("Cannot send message, websocket not ready");
        	return false;
        }
	}

	public function dispose()
	{
        _disposed = true;
		if (_socket != null) {
            Log.info("WebSockerConnection_socket.close");
			_socket.close();
            _socket = null;
		}
        _onerror = null;
        _onopen = null;
        _onmessage = null;
        _onclose = null;
	}

	function connect()
	{
        Log.info("WebSocketConnection connect");
		#if nodejs
			_socket = new WebSocket(this._url);
		#else
			untyped __js__('var WebSocket = WebSocket || window.WebSocket || window.MozWebSocket');
			_socket = untyped __js__('new WebSocket(this._url, [])');
		#end

		_socket.onerror = function (event) {
            Log.info("WebSocketConnection onerror " + event);
            var i = 0;
            while (i < _onerror.length) {
                if (_onerror[i] != null) {
                    _onerror[i](event);
                }
                i++;
            }
        };
        _socket.onopen = function () {
            Log.info("WebSocketConnection onopen ");
            var i = 0;
            while (i < _onopen.length) {
                if (_onopen[i] != null) {
                    _onopen[i]();
                }
                i++;
            }
            restartTimeoutTimer();
        };
        // _socket.onmessage = function (event :MessageEvent) {
        _socket.onmessage = function (event) {
            Log.info("WebSocketConnection onmessage " + event);
            Log.info("onmessage " + untyped event.data);
            var i = 0;
            while (i < _onmessage.length) {
                if (_onmessage[i] != null) {
                    try{
                        _onmessage[i](event);
                    } catch (e :Dynamic) {
                        Log.error(e);
                    }
                }
                i++;
            }
        };

        _socket.onclose = function (event) {
            Log.info("WebSocketConnection onclose " + event);
        	untyped clearInterval(_keepAliveTimoutId);
            _keepAliveTimoutId = 0;
            var i = 0;
            while (i < _onclose.length) {
                if (_onclose[i] != null) {
                    _onclose[i](event);
                }
                i++;
            }

            Log.info("onclose " + untyped JSON.stringify(event));
            // Log.info("...reconnecting");
            // _socket.onerror = null;
            // _socket.onopen = null;
            // _socket.onmessage = null;
            // _socket.onclose = null;
            _socket = null;
            if (!_disposed) {
                Log.info("reconnecting");
                untyped setTimout(function() {
                    connect();
                }, 1000);//Hardcode retry timer for now
            }
        };
	}

	function restartTimeoutTimer()
	{
		if (_keepAliveTimoutId != 0) {
			untyped clearInterval(_keepAliveTimoutId);
		}
        untyped _keepAliveTimoutId = setInterval(function() {
            Log.info("Keep alive ping");
            if (_socket != null && _socket.readyState == 1) {
                Log.info("sending ping");
                #if nodejs
                    _socket.ping("hey");
                #else
                    _socket.send("keep_alive");
                #end
            }
        }, _keepAliveMilliseconds);
	}

	var _socket :WebSocket;
	var _url :String;
	var _keepAliveMilliseconds :Int;
	var _keepAliveTimoutId :Int;

    var _onerror :Array<Dynamic->Void>;
    var _onopen :Array<Void->Void>;
    var _onmessage :Array<Dynamic->Void>;
    var _onclose :Array<Dynamic->Void>;
    var _disposed :Bool;
}