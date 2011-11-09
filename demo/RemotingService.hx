package ;

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

class RemotingService implements IRemotingService
{
	public function new ()
	{
	}
	
	@remote
	public function getFoos (cb: Array<String>->Void) :Void
	{
		cb(["foo1", "foo2", "foo3"]);
	}

	
	@remote
	public function getFoo (fooName :String, cb: String->Void) :Void
	{
		cb("foo1");
	}
}
