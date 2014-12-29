package websockets.buildInterfaceSupport;

import flambe.server.NodeRelay;
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

@:build(t9.remoting.Macros.remotingClass(true))
class RemotingServiceNodeRelay
	implements BuiltRemotingInterface
{
	public function new ()
	{
	}
	
	@remote
	public function getFoos (relay: flambe.server.NodeRelay<Array<String>>) :Void
	{
		relay.success(["foo1", "foo2", "foo3"]);
	}

	
	@remote
	public function getFoo (fooName :String, relay: flambe.server.NodeRelay<String>) :Void
	{
		relay.success("foo1");
	}
}
