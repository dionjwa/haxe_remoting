package demo.devserver;

import transition9.remoting.MiddlewareBuilder;
import transition9.remoting.NodeJsHtmlConnection;

import js.Node;
import js.node.Connect;

class RemotingServer
{
	public static function main()
	{
		//Import all classes to make sure everything compiles
		transition9.remoting.DebugAsyncConnection;
		transition9.remoting.DebugConnection;
		transition9.remoting.ExternalAsyncConnection;
		transition9.remoting.MiddlewareBuilder;
		transition9.remoting.NodeJsHtmlConnection;
		transition9.remoting.NodeJsHtmlConnectionJsonFallback;
		// demo.devserver.RemotingClient;
		transition9.websockets.WebsocketClient;
		#if flambe
		transition9.remoting.NodeJsRelayHtmlConnection;
		#end
		
		//https://github.com/visionmedia/commander.js
		var program :Dynamic= Node.require('commander');
		program
			.version('0.0.1')
			.option('-p, --port <port>', 'specify the port [8080]', untyped Number, 8080)
			.option('-w, --websocketport <websocketport>', 'specify the port [8081]', untyped Number, 8081)
			.parse(Node.process.argv);
  
		//http://www.senchalabs.org/connect/
		var connect :Connect = Node.require('connect');
		connect.createServer(
			connect.errorHandler({showStack:true, showMessage:true, dumpExceptions:true})
			,connect.favicon()
			// Create the server. Function passed as parameter is called on every request made.
			,new MiddlewareBuilder()
				//Add our example service
				.addRemotingManager(new demo.devserver.ExampleRemotingService())
				//Add more services here
				//.addRemotingManager(new your.CustomRemotingService())
				//Allow calling remoting services with url args and getting json back, useful for testing/debugging
				.allowJsonFallback()//
				.buildConnectMiddleware()//This can be checked quickly
			
		).listen(program.port, 'localhost');
		trace("Server listening on localhost:" + program.port);
	}
}
