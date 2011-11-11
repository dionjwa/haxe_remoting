package ;

import haxe.remoting.Context;
import haxe.remoting.NodeJsHtmlConnection;
import haxe.remoting.NodeJsRelayHtmlConnection;

import js.node.Connect;
import js.Node;

class Server
{
	public static function main ()
	{
		
		
		createNonRelayConnection();
		createNodeRelayConnection();
	}
	
	static function createNonRelayConnection () :Void
	{
		var context = new haxe.remoting.Context();
		
		var remotingmanager = new foo.RemotingService();
		context.addObject(haxe.remoting.Macros.getRemotingIdFromClassDef(foo.IRemotingService), remotingmanager);
		
		var remotingHandler = new NodeJsHtmlConnection(context);

		var remotingMiddleWare = function (req :NodeHttpServerReq, res :NodeHttpServerResp, next :Void->MiddleWare) :Void {
			if (!remotingHandler.handleRequest(req, res)) {
				next();
			}
		}
		
		var connect :Connect = Node.require('connect');
		
		trace("Listening on port 8000");
		connect.createServer(
			connect.errorHandler({showStack:true, showMessage:true, dumpExceptions:true})
			, remotingMiddleWare
			, function (req :NodeHttpServerReq, res :NodeHttpServerResp, next :Void->MiddleWare) :Void {
				if (req.url.length < 2) {
					res.write(html, "utf8");
					res.writeHead(200);
					res.end();
				} else {
					next();
				}
			} 
			//Issues with the 'static' keyword
			, untyped __js__("connect.static(__dirname)")
		).listen(8000, "127.0.0.1");
	}
	
	static function createNodeRelayConnection () :Void
	{
		var context = new haxe.remoting.Context();
		
		var remotingmanager = new foo.RemotingServiceNodeRelay();
		context.addObject(haxe.remoting.Macros.getRemotingIdFromClassDef(foo.RemotingServiceNodeRelay), remotingmanager);
		
		var remotingHandler = new NodeJsRelayHtmlConnection(context);

		var remotingMiddleWare = function (req :NodeHttpServerReq, res :NodeHttpServerResp, next :Void->MiddleWare) :Void {
			if (!remotingHandler.handleRequest(req, res)) {
				next();
			}
		}
		
		var connect :Connect = Node.require('connect');
		
		trace("Listening on port 8001");
		connect.createServer(
			connect.errorHandler({showStack:true, showMessage:true, dumpExceptions:true})
			, remotingMiddleWare
			, function (req :NodeHttpServerReq, res :NodeHttpServerResp, next :Void->MiddleWare) :Void {
				if (req.url.length < 2) {
					res.write(html, "utf8");
					res.writeHead(200);
					res.end();
				} else {
					next();
				}
			} 
			//Issues with the 'static' keyword
			, untyped __js__("connect.static(__dirname)")
		).listen(8001, "127.0.0.1");
	}
	
	static var html = '<!DOCTYPE html>
		<html lang="en">
		<head>
		<meta charset="utf-8">
		<title>Remoting tests</title>
		
		</head>
		<body>
		<div id="haxe:trace"></div>
		<script src="client.js"></script>
		</body>
		</html>';

}
