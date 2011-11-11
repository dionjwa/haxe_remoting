package ;


/**
  * Go to http://localhost:8000 for one client, and http://localhost:8001 for the other.
  */
class Client
{
	public static function main ()
	{
		var conn1 = haxe.remoting.HttpAsyncConnection.urlConnect("http://localhost:8000");
		conn1.setErrorHandler( function(err) trace("Error : " + err));
		
		var conn2 = haxe.remoting.HttpAsyncConnection.urlConnect("http://localhost:8001");
		conn2.setErrorHandler( function(err) trace("Error : " + err));

		var str = new String("dsdsffd");
		str.charAt(1);
		
		var nonNodeRelayProxy = new foo.RemotingProxy(conn1);
		nonNodeRelayProxy.getFoos(function (foos :Array<String>) :Void {
			trace("successfully called non-NodeRelay proxy, foos=" + foos);
		});

		var nodeRelayProxy = haxe.remoting.Macros.buildRemoteProxyClass(foo.RemotingServiceNodeRelay, conn2);
		
		nodeRelayProxy.getFoos(function (foos :Array<String>) :Void {
			trace("successfully called NodeRelay proxy, foos=" + foos);
		});	
	}

}
