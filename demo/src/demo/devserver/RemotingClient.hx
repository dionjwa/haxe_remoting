package demo.devserver;

import js.Node;

import transition9.remoting.NodeJsHtmlConnection;

using StringTools;

class RemotingClient
{
	public static function main()
	{
		//https://github.com/visionmedia/commander.js
		var program :Dynamic= Node.require('commander');
		program
			.version('0.0.1')
			.option('-p, --port <port>', 'specify the port [8080]', untyped Number, 8080)
			.parse(Node.process.argv);
  
		//Create the remoting Html connection
		var url = "http://localhost:" + program.port;
		var conn = haxe.remoting.HttpAsyncConnection.urlConnect(url);
		conn.setErrorHandler(function(error) {
			// #if flambe
			// Log.error(error + "\n" + haxe.CallStack.toString(haxe.CallStack.callStack()));
			// #else
			trace("error", error + "\n" + haxe.CallStack.toString(haxe.CallStack.callStack()));
			// #end
			
		});
		
		//We need to declare the proxy class here.
		// demo.devserver.ExampleRemotingService;
		
		
		//Build and instantiate the proxy class with macros.  
		var exampleProxy = transition9.remoting.Macros.buildAndInstantiateRemoteProxyClass(
			demo.devserver.ExampleRemotingService, 
			conn);
		
		//Query the remote demo.devserver.ExampleRemotingService
		//Prompt for input, send to the server, and print the result
		var queryAndSendUserInput = null;
		queryAndSendUserInput = function(?query :String = null) :Void {
			program.prompt(query != null ? query : 'Enter number: ', function(n :String) {
				var input = Std.parseInt(n.trim());
				// Log.info("input: " + input);
				if (input == null || Math.isNaN(input)) {
					queryAndSendUserInput("Not a valid number, try again:");
				} else {
					exampleProxy.processInput(input, function(result :Int) {
						#if flambe
						Log.info("Result from server " + Node.stringify(result));
						#else
						trace("Result from server " + Node.stringify(result));
						#end
						queryAndSendUserInput(null);
					});
				}
			});
		}
		
		queryAndSendUserInput(null);
	}
}
