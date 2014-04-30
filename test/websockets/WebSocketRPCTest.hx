package websockets;

import com.dongxiguo.continuation.Async;

import haxe.Json;

import transition9.remoting.jsonrpc.Context;
import transition9.remoting.jsonrpc.RPC;
import transition9.remoting.jsonrpc.ConnectionClient;
import transition9.remoting.jsonrpc.ClientConnectionWebSocket;
import transition9.remoting.jsonrpc.WebSocketRouter;
import transition9.async.Step;

import js.Node;
import js.node.WebSocketServer;
import js.node.WebSocket;

class WebSocketRPCTest extends WebSocketTestBase
	implements Async
{
	var _webSocketRouter :WebSocketRouter;

	public function new()
	{
		super();
	}

	override public function setup(cb :Void->Void)
	{
		super.setup(function() {
			_webSocketRouter = new WebSocketRouter(_webSocketServer);
			cb();
		});
	}

	override public function tearDown(cb :Void->Void)
	{
		super.tearDown(function() {
			_webSocketRouter.dispose();
			_webSocketRouter = null;
			cb();
		});
	}

	@AsyncTest
	@async
	public function testBasicWebSocketRPC (onTestFinish :Err->Void) :Void
	{
		var context = new Context();
		context.registerService(new websockets.buildInterfaceSupport.RemotingManager());
		_webSocketRouter.setContext(context);
		var websocketConnection = new transition9.websockets.WebSocketConnection("http://localhost:" + _port);
		websocketConnection.registerOnClose(function(event) {
			Log.info("websocketConnection.onclose");
		});
		@await websocketConnection.registerOnOpen();
		var rpcconnection = new ClientConnectionWebSocket(websocketConnection);
		var service = transition9.remoting.jsonrpc.Macros.buildAndInstantiateRemoteProxyClass(websockets.buildInterfaceSupport.RemotingManager, rpcconnection, false);
		service.getFoo("test", function(err :ResponseError, foo :String) {
			service.getFoos(function(err :ResponseError, foos :Array<String>) {
				onTestFinish(err);
			});
		});
	}
}

class DummyRpcConnection
	implements transition9.remoting.jsonrpc.ConnectionClient
{
	public function new() {}

	public function addResponseListener(onResponse :ResponseDef->Void) : {dispose:Void->Void}
	{
		return {dispose:function(){}};
	}

	public function sendRequest(request :RequestDef) :Void
	{
	}

	public function sendRequests(requests :Array<RequestDef>) :Void
	{
	}
}