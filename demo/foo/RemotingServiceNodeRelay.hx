package foo;

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

@remoteId("fooService")
class RemotingServiceNodeRelay
{
	public function new ()
	{
	}
	
	@remote
	public function getFoos (relay: haxe.remoting.NodeRelay<Array<String>>) :Void
	{
		relay.success(["foo1", "foo2", "foo3"]);
	}

	
	@remote
	public function getFoo (fooName :String, relay: haxe.remoting.NodeRelay<String>) :Void
	{
		relay.success("foo1");
	}
}
