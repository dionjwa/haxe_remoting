package t9.websockets;
/**
 * A wrapper around a websocket that reconnects if disconnected.
 * Flaky connections are part of the mobile world.
 */

import haxe.Timer;

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

enum ReconnectType {
    None;//Acts like a regular websocket. No logic for handling reconnects.
    Repeat(intervalMilliseconds :Int);
    Decay(intervalMilliseconds :Int, intervalMultipler :Float);
}

/**
 * This will reconnect if dropped.
 * TODO: decaying reconnect time, and optional fallback urls.
 */
class WebSocketConnection
{
    public var url (get, null) :String;

    public function setKeepAliveMilliseconds(ms :Int) :WebSocketConnection
    {
        _keepAliveMilliseconds = ms;
        return this;
    }

    public function setReconnectionType(reconnectType :ReconnectType) :WebSocketConnection
    {
        _reconnectType = reconnectType;
        return this;
    }

    /**
     *
     */
	public function new(url :String)
	{
        _onDispose = [];
        _onerror = [];
        _onopen = [];
        _onmessage = [];
        _onclose = [];
		_url = url;
		_keepAliveMilliseconds = 25000;
        setReconnectionType(Repeat(500));
        _reconnectAttempts = 0;
        _disposed = false;
        connect();

#if cocos2dx
        //Maybe move this block elsewhere
        /* Disconnect and reconnect on foreground/background. */
        var listener1 = CC.eventManager.addCustomListener(CC.game.EVENT_HIDE, function () {
            Log.info("Disconnecting websocket after hide");
            disconnect();
        });
        var listener2 = CC.eventManager.addCustomListener(CC.game.EVENT_SHOW, function () {
            Log.info("Reconnecting websocket after show");
            connect();
        });
        _onDispose.push(function() {
            CC.eventManager.removeEventListener(listener1);
            CC.eventManager.removeEventListener(listener2);
        });
#end
	}

    public function registerOnError(onError :Dynamic->Void) :{dispose:Void->Void}
    {
        _onerror.push(onError);
        var index = _onerror.length - 1;
        return {dispose:function() {
#if debug
            Log.info("WebSocketConnection removing onError");
#end
            _onerror[index] = null;
        }};
    }

    public function registerOnOpen(onOpen :Void->Void) :{dispose:Void->Void}
    {
        _onopen.push(onOpen);
        var index = _onopen.length - 1;
        var disposable = {dispose:function() {
#if debug
            Log.info("WebSocketConnection removing onOpen");
#end
            _onopen[index] = null;
        }};

        //If the websocket is already open, call the callback on the next tick
        haxe.Timer.delay(function() {
            if (_socket != null && _socket.readyState == js.html.WebSocket.OPEN) {
                if (!_disposed) {
                    onOpen();
                }
            }
        }, 0);
        return disposable;
    }

    public function registerOnMessage(onMessage :Dynamic->Void) :{dispose:Void->Void}
    {
        _onmessage.push(onMessage);
        var index = _onmessage.length - 1;
        return {dispose:function() {
#if debug
            Log.info("WebSocketConnection removing onMessage");
#end
            _onmessage[index] = null;
        }};
    }

    public function registerOnClose(onClose :Dynamic->Void) :{dispose:Void->Void}
    {
        _onclose.push(onClose);
        var index = _onclose.length - 1;
        return {dispose:function() {
#if debug
            Log.info("WebSocketConnection removing onClose");
#end
            _onclose[index] = null;
        }};
    }

	public function send(data) :Bool
	{
// #if debug
//         Log.info('send _socket=${_socket != null} _socket.readyState=' + (_socket != null ? _socket.readyState : -1));
// #end
		if (_socket != null && _socket.readyState == 1) {
// #if debug
//             Log.info('sending via ACTUAL socket: ' + data);
// #end
            _socket.send(data);
// #if debug
//             Log.info('finished sending via ACTUAL socket: ');
// #end
        	return true;
        } else {
#if debug
        	Log.warn("Cannot send message, websocket not ready");
#end
        	return false;
        }
	}

	public function dispose()
	{
        _disposed = true;
        _onerror = null;
        _onopen = null;
        _onmessage = null;
        _onclose = null;
        disconnect();
	}

	function connect()
	{
        _isDisconnected = false;
// #if debug
//         Log.info("WebSocketConnection connect");
// #end
		#if nodejs
			_socket = new WebSocket(this._url);
		#else
			untyped __js__('var WebSocket = WebSocket || window.WebSocket || window.MozWebSocket');
			_socket = untyped __js__('new WebSocket(this._url)');
		#end

		_socket.onerror = function (event :Dynamic) :Void {
            var i = 0;
            while (_onerror != null && i < _onerror.length) {
                if (_onerror[i] != null) {
                    _onerror[i](event);
                    i++;
                } else {
                    _onerror.splice(i, 1);
                }
            }
        };
#if nodejs
        _socket.onopen = function () :Void {
#else
        _socket.onopen = function (event :Dynamic) :Void {
#end
            var i = 0;
            while (_onopen != null && i < _onopen.length) {
                if (_onopen[i] != null) {
                    _onopen[i]();
                    i++;
                } else {
                    _onopen.splice(i, 1);
                }
            }
            _reconnectAttempts = 0;
            restartTimeoutTimer();
        };
        _socket.onmessage = function (event :Dynamic) :Void {
            var i = 0;
            while (_onmessage != null && i < _onmessage.length) {
                if (_onmessage[i] != null) {
                    try{
                        _onmessage[i](event);
                    } catch (e :Dynamic) {
                        Log.error(e);
                    }
                    i++;
                } else {
                    _onmessage.splice(i, 1);
                }
            }
        };

        _socket.onclose = function (event) {
            if (_keepAliveTimer != null) {
                _keepAliveTimer.stop();
                _keepAliveTimer = null;
            }
            var i = 0;
            while (_onclose != null && i < _onclose.length) {
                if (_onclose[i] != null) {
                    _onclose[i](event);
                    i++;
                } else {
                    _onclose.splice(i, 1);
                }
            }
            if (_disposed) {
                _socket.onerror = null;
                _socket.onopen = null;
                _socket.onmessage = null;
                _socket.onclose = null;
            } else {
                if (!_isDisconnected) {
                    var reconnectInterval = 0;
                    switch(_reconnectType) {
                        case None:
                            Log.info("No reconnects because ReconnectType==None");
                        case Repeat(intervalMilliseconds):
                            Log.info("reconnecting");
                            reconnectInterval = intervalMilliseconds;
                        case Decay(intervalMilliseconds, intervalMultipler):
                            reconnectInterval = Std.int(intervalMilliseconds * (intervalMultipler * (_reconnectAttempts + 1)));
                            Log.info("reconnecting");
                    }
                    if (reconnectInterval > 0) {
                        haxe.Timer.delay(
                            function() {
                                if (!_disposed && !_isDisconnected) {
                                    _reconnectAttempts++;
                                    connect();
                                }
                            }, reconnectInterval);
                    }
                }
            }
            _socket = null;
        };
	}

    public function disconnect()
    {
        _isDisconnected = true;
        if (_keepAliveTimer != null) {
            _keepAliveTimer.stop();
            _keepAliveTimer = null;
        }
        if (_socket != null) {
// #if debug
//             Log.info("WebSockerConnection_socket.close");
// #end
            _socket.close();
            _socket = null;
        }
    }


	function restartTimeoutTimer()
	{
		if (_keepAliveTimer != null) {
            _keepAliveTimer.stop();
            _keepAliveTimer = null;
		}
        _keepAliveTimer = new Timer(_keepAliveMilliseconds);
        _keepAliveTimer.run = function() {
#if debug
            Log.info("Keep alive ping");
#end
            if (_socket != null && _socket.readyState == 1) {
#if debug
                Log.info("sending ping");
#end
                #if nodejs
                    _socket.ping("hey");
                #else
                    _socket.send("keep_alive");
                #end
            }
        }
	}

    inline function get_url() :String
    {
        return _url;
    }

	var _socket :WebSocket;
	var _url :String;
    var _reconnectType :ReconnectType;
	var _keepAliveMilliseconds :Int;
    var _keepAliveTimer :Timer;
    var _reconnectAttempts :Int;

    var _onerror :Array<Dynamic->Void>;
    var _onopen :Array<Void->Void>;
    var _onmessage :Array<Dynamic->Void>;
    var _onclose :Array<Dynamic->Void>;
    var _disposed :Bool;
    var _isDisconnected :Bool;
    var _onDispose :Array<Void->Void>;
}