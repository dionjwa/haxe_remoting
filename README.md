[haxe]: http://http://haxe.org

# Remoting classes for [Haxe][haxe]

This package consists of:

1. Node.js remoting connections, one using NodeRelay<T> (thanks Bruno), the other not.
2. Macros to build async client proxy remoting classes from interfaces or the server remoting class.  All server classes are excluded from the client.
3. Flash <-> JS asynchronous remoting connection (ExternalAsyncConnection)

See the demo for a working example.

## Running the demo

You need the following npm modules: connect
Then:

	haxe etc/build.hxml
	
	node server.js
	
Then navigate to http://localhost:8000 and http://localhost:8001

Both should show 1 error and 1 success.
