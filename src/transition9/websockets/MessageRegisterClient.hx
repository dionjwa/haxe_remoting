package transition9.websockets;

@:autoBuild(transition9.remoting.Macros.buildWebsocketMessage())
class MessageRegisterClient
{
	@serialize
	public var clientId :String;
	
	public function new (clientId :String)
	{
		this.clientId = clientId;
	}
}
