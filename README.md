[haxe]: http://http://haxe.org
[flambe]:http://lib.haxe.org/p/flambe
[wafl]:https://github.com/aduros/flambe/wiki/Wafl
[nodejs]:http://nodejs.org/

# Asynchronous remoting classes for [Haxe][haxe]

This package consists of:

1. Node.js remoting connections, one using NodeRelay<T> (thanks Bruno Garcia), the other not.
2. Macros to build async client proxy remoting classes from interfaces or the server remoting class.  All server classes are excluded from the client.
3. Flash <-> JS asynchronous remoting connection (ExternalAsyncConnection)

See the demo for a working example.

## Installation/compilation

To build the demos:

1. [Install node.js][nodejs].
1. [Install flambe](https://github.com/aduros/flambe/wiki/Installation).
2. Configure and run wafl (in the library root):

	wafl configure --debug
	wafl install
	
	
To run the remoting demo:

- In one terminal window run the server:
	
	node deploy/remoting-server-server/remoting-server.js

- In another terminal window, run the client:
	
	node deploy/remoting-client-server/remoting-client.js
	
In the client window, type a number and then enter.  The server sends back a processed result.


## Usage (building your own remoting classes)

Assume you have a remoting class on the server:

	package foo;

	@:build(haxe.remoting.Macros.remotingClass())
	class FooRemote
	{
		@remote
		public function getTheFoo(fooId :String, cb :String->Void) :Void
		{
			cb("someFoo");
		}
	}
	
On the client, you can construct a fully typed proxy async remoting class with:

	//Create the remoting Html connection
	var conn = haxe.remoting.HttpAsyncConnection.urlConnect("http://localhost:8000");
	
	//Build and instantiate the proxy class with macros.  
	//The full path to the server class is given as a String, but it is NOT compiled into the client.
	//It can be given as a class declaration, but then it is compiled into the client (not what you want)
	var fooProxy = haxe.remoting.Macros.buildAndInstantiateRemoteProxyClass(foo.FooRemote, conn);
	
	//You can use code completion here
	fooProxy.getTheFoo("fooId", function (foo :String) :Void {
		trace("successfully got the foo=" + foo);
	});
	
Instead of a remoting class, you can also build the proxy from an interface:

	interface FooRemote
	{
		@remote
		public function getTheFoo(fooId :String, cb :String->Void) :Void;
	}
	
You can also create an interface from the remoting class:

	@:build(haxe.remoting.Macros.addRemoteMethodsToInterfaceFrom("foo.FooRemote"))
	interface FooService {}
	
Then the client proxy class is declared with

	@:build(haxe.remoting.Macros.buildAsyncProxyClassFromInterface(FooRemote))
	//Or @:build(haxe.remoting.Macros.buildAsyncProxyClassFromInterface("foo.FooRemote"))
	class FooProxy implements IRemotingService {}:
	
In the future, you will be able to build and instantiate the interface derived proxy the same as the class derived proxy above.

## Running the unit tests

There are two unit tests:

	./test/runtests.sh
	
## Coming soon:

Websockets.
