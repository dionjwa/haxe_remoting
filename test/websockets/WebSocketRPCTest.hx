package websockets;

import haxe.Json;

import transition9.remoting.jsonrpc.RPCConnectionWebsocket;
import transition9.async.Step;

import js.Node;
import js.node.WebSocketServer;
import js.node.WebSocket;

class WebSocketRPCTest extends WebSocketTestBase
{
	public function new()
	{
		super();
		websocketPort = 8007;
	}

	@AsyncTest
	public function testBasicWebSocketConnection (onTestFinish :Err->Void, assert :Bool->?Dynamic->Void) :Void
	{
		var madeConnection = false;
		var clientSentMessage = false;
		var clientRecievedMessage = false;
		var clientGotOnCloseEvent = false;
		var step = new Step();
		var address = "http://localhost:" + _websocketPortsdfsdf;
		var messageToExchange = "This is the message!";
		var serverClientConnection :WebSocketConnection;

		var onConnectFailed = function() {
			step.error("onConnectFailed");
		}

		var clientConnectedCallback :Dynamic->Dynamic->Void = null;
		var serverConnectedCallback :Dynamic->Dynamic->Void = null;

		var onWebsocketRequest = function(request :WebSocketRequest) {
			serverClientConnection = request.accept(null, request.origin);
			serverConnectedCallback(null, "ServerConnected");
			Log.info(Date.now() + ' Connection accepted.');
			serverClientConnection.on('message', function(message :WebSocketMessage) {
				if (message.type == 'utf8') {
					Log.info('Received Message: ' + message.utf8Data);
					if (clientSentMessage) {
						step.error("Client already sent a message");
						return;
					}
					if (message.utf8Data == messageToExchange) {
						clientSentMessage = true;
						step.cb0();
					} else {
						step.error("Client sent wrong message");
					}
				}
				else if (message.type == 'binary') {
					Log.info('Received Binary Message of ' + message.binaryData.length + ' bytes');
				}
			});
			serverClientConnection.on('close', function(reasonCode, description) {
				Log.info(Date.now() + ' Peer ' + serverClientConnection.remoteAddress + ' disconnected.');
			});
			serverClientConnection.on('error', function(error) {
				Log.error(Date.now() + ' Error: ' + error);
				onTestFinish(error);
			});
		}

		var websocketClient :WebSocket;

		step.chain(
		[
			//WebsocketServer connected and ready, Set up the client
			function (err :Err) :Void {
				// websocketServer = ws;
				websocketServer.on('connectFailed', onConnectFailed);
				websocketServer.on('request', onWebsocketRequest);

				Log.info("Client attempted to connect to " + address);
				websocketClient = new WebSocket(address);

				clientConnectedCallback = step.parallel();
				serverConnectedCallback = step.parallel();

				websocketClient.onclose = function(event) {
					Log.info("websocketClient.onclose: madeConnection=" + madeConnection + ", evt=" + event);
					assert(madeConnection, "Failed to make connection before websocket client closed");
					clientGotOnCloseEvent = true;
					step.cb(null, true);
				}
				websocketClient.onerror = function(err) {
					Log.error("websocketClient.onerror: " + err);
					step.error("websocket client error:" + err);
				}
				websocketClient.onmessage = function(message :ClientMessage) {
					trace("Client received message: " + Json.stringify(message));
					if (clientRecievedMessage) {
						Log.error("Client already received message");
						step.error("Client already received message");
						return;
					}
					if (messageToExchange == message.data) {
						Log.info("Message is good");
						step.cb0();
					} else {
						Log.error("Client got the wrong message");
						step.error("Client got the wrong message");
					}
				}
				websocketClient.onopen = function(event) {
					trace("Client connection opened ");
					madeConnection = true;
					clientConnectedCallback(null, "ClientConnected");
				}
			},
			//Send the message from the client
			function (err :Dynamic, input1 :String, input2 :String) :Void {
				Log.info("Connected: " + input1 + " " + input2 + (err != null ? ", err=" + err : ""));
				if (err == null) {
					Log.info("Client successfully connected, now sending message");
					websocketClient.send(messageToExchange);
				} else {
					Log.info("Passing on error");
					step.error(err);
				}
			},
			//Send the message from the server
			function (err :Dynamic, input :String) :Void {
				if (err == null) {
					Log.info("Client successfully sent message to server, now server sends message back to client");
					serverClientConnection.sendUTF(messageToExchange);
				} else {
					step.error(err);
				}
			},
			//Close the client connection
			function (err :Dynamic, input :String) :Void {
				if (err == null) {
					Log.info("Client received message from server, now closing");
					websocketClient.close();
				} else {
					step.error(err);
				}
			},
			//After the client closed
			function (err, didGetCloseEvent :Bool) {
				if (err != null || !didGetCloseEvent) {
					onTestFinish(err != null ? err : "failed to get close event");
				} else {
					onTestFinish(null);
				}
			}
		]);
	}
}