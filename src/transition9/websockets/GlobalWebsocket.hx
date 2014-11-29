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
 * Static functions for managing a global websocket
 * connectino shared by multiple services. Most useful
 * on clients.
 */
class GlobalWebsocket
{
	public static var global (get, null) :WebSocketConnection;
    inline static function get_global() :WebSocketConnection
    {
        return Global.object()[GLOBAL_KEY_WEBSOCKET_PRIMARY];
    }

#if cocos2dx
    public static function get(url :String) :WebSocketConnection
    {
        var G = Global.object();
        var connections :Map<String, WebSocketConnection> = G[GLOBAL_KEY_WEBSOCKET_CONNECTIONS];
        if (connections == null) {
            connections = new Map<String, WebSocketConnection>();
            G[GLOBAL_KEY_WEBSOCKET_CONNECTIONS] = connections;
        }
        if (connections[url] == null) {
            var ws = new WebSocketConnection(url);
            connections[url] = ws;
        }
        return connections[url];
    }
#else
    static var CONNECTIONS :Map<String, WebSocketConnection> = new Map();
    public static function get(url :String) :WebSocketConnection
    {
        if (!CONNECTIONS.exists(url)) {
            CONNECTIONS[url] = new WebSocketConnection(url);
        }
        return CONNECTIONS[url];
    }
#end
	public function setAsGlobalPrimary()
    {
        var G = Global.object();
        G[GLOBAL_KEY_WEBSOCKET_PRIMARY] = this;

        var connections :Map<String, WebSocketConnection> = G[GLOBAL_KEY_WEBSOCKET_CONNECTIONS];
        if (connections == null) {
            connections = new Map<String, WebSocketConnection>();
            G[GLOBAL_KEY_WEBSOCKET_CONNECTIONS] = connections;
        }
        connections[_url] = this;

        return this;
    }

    static inline var GLOBAL_KEY_WEBSOCKET_PRIMARY = "hx_websocketConnectionPrimary";
    static inline var GLOBAL_KEY_WEBSOCKET_CONNECTIONS = "hx_websocketConnections";
}