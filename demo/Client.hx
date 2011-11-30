package ;

import serialization.support.RedisSerializableClass;
import haxe.serialization.Serialization;


/**
  * Go to http://localhost:8000 for one client, and http://localhost:8001 for the other.
  */
class Client
{
	public static function main ()
	{
		
		var toSerialize = new RedisSerializableClass();
		
		var var1 = "someTestString";
		var var2 = 7;
		
		
		toSerialize.var1 = var1;
		toSerialize.var2 = var2;
		trace('toSerialize=' + toSerialize);
		
		var array = Serialization.classToArray(toSerialize);
		
		var deserialized :RedisSerializableClass = Serialization.arrayToClass(array, RedisSerializableClass);
		trace('deserialized=' + deserialized);
		
		
		
		// var conn1 = haxe.remoting.HttpAsyncConnection.urlConnect("http://localhost:8000");
		// conn1.setErrorHandler( function(err) trace("Error : " + err));
		
		// var conn2 = haxe.remoting.HttpAsyncConnection.urlConnect("http://localhost:8001");
		// conn2.setErrorHandler( function(err) trace("Error : " + err));

		// var str = new String("dsdsffd");
		// str.charAt(1);
		
		// var nonNodeRelayProxy = new foo.RemotingProxy(conn1);
		// nonNodeRelayProxy.getFoos(function (foos :Array<String>) :Void {
		// 	trace("successfully called non-NodeRelay proxy, foos=" + foos);
		// });

		// var nodeRelayProxy = haxe.remoting.Macros.buildRemoteProxyClass(foo.RemotingServiceNodeRelay, conn2);
		
		// nodeRelayProxy.getFoos(function (foos :Array<String>) :Void {
		// 	trace("successfully called NodeRelay proxy, foos=" + foos);
		// });	
	}

}
