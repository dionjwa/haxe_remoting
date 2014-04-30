package websockets.buildInterfaceSupport;

import transition9.remoting.jsonrpc.RPCProxy;
import transition9.remoting.jsonrpc.RPCConnection;

/**
  * Remoting methods are added from the RemotingManager class.
  */
// @:build(transition9.remoting.jsonrpc.Macros.addProxyMethods(websockets.buildInterfaceSupport.RemotingManager))
class RemotingService extends RPCProxy
{
	public function new(conn :RPCConnection)
	{
		super(conn);
	}
}
