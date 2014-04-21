package remoting;

import flambe.util.Assert;

import js.Node;

import remoting.buildInterfaceSupport.BuiltRemotingService;
import remoting.buildInterfaceSupport.RemotingManager;
import transition9.remoting.RemotingUtil;

using Lambda;

using StringTools;

/**
 * Serialization tests
 */
class RemotingTest
{
	public function new()
	{
	}

	@Before
	public function setup (cb :Void->Void) :Void
	{
		Log.info("setup");
		cb();
	}

	@After
	public function tearDown (cb :Void->Void) :Void
	{
		Log.info("tearDown");
		cb();
	}

	/**
	  * Make sure the interface has all the methods in the remoting
	  * class with a @remote metadata label.
	  */
	@Test
	public function testBuildingRemotingInterface():Void
	{
		var meta = haxe.rtti.Meta.getFields(RemotingManager);
		Assert.that(meta != null);
		var totalRemotingFields = 0;
		for (fieldName in Type.getInstanceFields(RemotingManager)) {
			if (Reflect.hasField(meta, fieldName) && Reflect.hasField(Reflect.field(meta, fieldName), "remote")) {
				Assert.that(Type.getInstanceFields(BuiltRemotingService).has(fieldName));
				totalRemotingFields++;
			}
		}
		Assert.that(totalRemotingFields == 2);
	}

	/**
	  * Make sure the interface has all the methods in the remoting
	  * class with a @remote metadata label.
	  */
	@Test
	public function testBuildingRemotingClientClass():Void
	{
		var meta = haxe.rtti.Meta.getFields(RemotingManager);
		Assert.that(meta != null);
		var totalRemotingFields = 0;

		var remotingClientInstance =
			transition9.remoting.Macros.buildAndInstantiateRemoteProxyClass(
				"remoting.buildInterfaceSupport.RemotingManager",
				new DummyConnection());

		var remotingClass = Type.getClass(remotingClientInstance);

		for (fieldName in Type.getInstanceFields(RemotingManager)) {
			if (Reflect.hasField(meta, fieldName) && Reflect.hasField(Reflect.field(meta, fieldName), "remote")) {
				Assert.that(Type.getInstanceFields(remotingClass).has(fieldName));
				totalRemotingFields++;
			}
		}
		Assert.that(totalRemotingFields == 2);
	}

	/**
	  * Make sure the build remoting server class has the added static fields
	  */
	@Test
	public function testBuildingRemotingManager():Void
	{
		var cls = RemotingManager;
		Assert.that(Reflect.field(RemotingManager, RemotingUtil.REMOTING_ID_NAME) != null);
		Assert.that(Reflect.field(RemotingManager, RemotingUtil.REMOTING_INTERFACE_NAME) != null);
	}
}

class DummyConnection
	implements haxe.remoting.AsyncConnection
{
	public function new() {}
	public function call( params : Array<Dynamic>, ?result : Dynamic -> Void ) : Void {}
	public function resolve( name : String ) : haxe.remoting.AsyncConnection {return null;}
	public function setErrorHandler( error : Dynamic -> Void ) : Void {}
}
