package foo;

@:build(haxe.remoting.Macros.buildAsyncProxyClassFromInterface(foo.IRemotingService))
class RemotingProxy implements IRemotingService 
{}
