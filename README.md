[haxe]: http://http://haxe.org

# Asynchronous remoting classes for [Haxe][haxe]

This package consists of:

1. Node.js remoting connections, one using NodeRelay<T> (thanks Bruno), the other not.
2. Macros to build async client proxy remoting classes from interfaces or the server remoting class.  All server classes are excluded from the client.
3. Flash <-> JS asynchronous remoting connection (ExternalAsyncConnection)

See the demo for a working example.

## Usage

Assume you have a remoting class on the server:

	@remoteId("fooService")
	class FooRemote
	{
		@remote
		public function getTheFoo(fooId :String, relay: NodeRelay<String>) :Void
		{
			relay.onSuccess("someFoo");
		}
	}
	
On the client, you can construct a fully typed proxy async remoting class with:

	//Create the remoting Html connection
	var conn = haxe.remoting.HttpAsyncConnection.urlConnect("http://localhost:8000");
	
	//Build and instantiate the proxy class with macros.  The server class is declared here, but NOT compiled into the client.
	var fooProxy = haxe.remoting.Macros.buildRemoteProxyClass(FooRemote, conn);
	
	//You can use code completion here
	fooProxy.getTheFoo(function (foo :String) :Void {
		trace("successfully got the foo=" + foo);
	});
	
	
Instead of a remoting class, you can also build the proxy from an interface (also we're not using NodeRelay<T> here):

	@remoteId("fooService")
	interface FooRemote
	{
		@remote
		public function getTheFoo(fooId :String, cb :String->Void) :Void;
	}
	
Then the client proxy class is declared with

	@:build(haxe.remoting.Macros.buildAsyncProxyClassFromInterface(FooRemote))
	class FooProxy implements IRemotingService {}:
	
In the future, you will be able to build and instantiate the interface derived proxy the same as the class derived proxy above.


## Running the demo

You need the following npm modules: connect
Then:

	haxe etc/build.hxml
	
	node server.js
	
Then navigate to http://localhost:8000 and http://localhost:8001

Both should show 1 error and 1 success.  Yeah, this demo could be better.
