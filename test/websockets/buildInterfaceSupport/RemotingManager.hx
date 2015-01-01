package websockets.buildInterfaceSupport;

import haxe.remoting.JsonRPC;
/**
  * This remoting class does not use interfaces.  The client proxy is built via:
  *
  * haxe.remoting.Macros.buildRemoteProxyClass(net.amago.turngame.server.levels.LevelManager);
		var proxyClass = haxe.remoting.Macros.getRemoteProxyClass(net.amago.turngame.server.levels.LevelManager);
		trace('proxyClass=' + Std.string(proxyClass));
		// trace('fields=' + Type.getInstanceFields(proxyClass));
		var levelsProxy = Type.createInstance(proxyClass, [conn]);
		levelsProxy.getAllLevelNames(cb);
  */

// @:build(t9.remoting.jsonrpc.Macros.remotingClass())
class RemotingManager
	implements t9.remoting.jsonrpc.RemotingService
{
	public function new ()
	{
	}

	@remote
	public function getFoos (cb: haxe.remoting.JsonRPC.ResponseError->Array<String>->Void)
	{
		// Log.info('RemotingManager.getFoos(...) cb=$cb');
		Assert.that(cb != null, "cb==null");
		Assert.that(cb != null, "cb==null");
		switch(Type.typeof(cb)) {
			case TFunction://good
			default: Log.error("cb is not a function");
		}
		switch(Type.typeof(cb)) {
			case TFunction://good
			default: Log.error("cb is not a function");
		}
		cb(null, ["foo1", "foo2", "foo3"]);
	}

	@remote
	public function getFoo (fooName :String, cb: haxe.remoting.JsonRPC.ResponseError->String->Void)
	{
		// Log.info('RemotingManager.getFoo(fooName=$fooName)');
		// Log.info('cb=$cb');
		Assert.that(cb != null, "cb==null");
		switch(Type.typeof(cb)) {
			case TFunction://good
			default: Log.error("cb is not a function");
		}
		cb(null, "foo1");
	}

	public function nonRemotingMethod (cb: haxe.remoting.JsonRPC.ResponseError->Array<String>->Void)
	{
		cb(null, ["foo1", "foo2", "foo3"]);
	}
}
