package remoting.buildInterfaceSupport;

/**
  * Interface methods are added from the RemotingService class.
  */
@:build(transition9.remoting.Macros.addRemoteMethodsToInterfaceFrom(remoting.buildInterfaceSupport.RemotingManager))
interface BuiltRemotingService {}
