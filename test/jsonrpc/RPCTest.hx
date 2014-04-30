package websockets;

import haxe.Json;

import transition9.remoting.jsonrpc.RPCConnectionWebsocket;
import transition9.async.Step;

import js.Node;
import js.node.WebSocketServer;
import js.node.WebSocket;

typedef Err = Dynamic;

class RPCTest extends websockets.WebSocketTestBase
{
	public function new()
	{
		super();
	}

	override public function setup(cb :Void->Void)
	{
		cb();
	}

	public function tearDown(cb :Err->Void)
	{
		cb(null);
	}

	@AsyncTest
	public function testBasicWebSocketConnection (onTestFinish :Err->Void) :Void
	{
		onTestFinish(null);
	}

}