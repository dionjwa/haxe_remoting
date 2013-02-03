package demo.devserver;

@:autoBuild(transition9.remoting.Macros.buildWebsocketMessage())
class TestMessageType1
{
	public function new (originId :String)
	{
		this.originId = originId;
	}
	
	@serialize
	public var originId :String;

}
