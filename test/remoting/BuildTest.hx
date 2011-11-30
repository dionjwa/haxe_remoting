package remoting;

import utest.Assert;

import remoting.buildInterfaceSupport.BuiltRemotingService;
import remoting.buildInterfaceSupport.RemotingManager;


using Lambda;

/**
* Auto generated ExampleTest for MassiveUnit. 
* This is an example test class can be used as a template for writing normal and async tests 
* Refer to munit command line tool for more information (haxelib run munit)
*/
class BuildTest 
{
	private var timer :haxe.Timer;
	
	public function new() 
	{
		
	}
	
	@BeforeClass
	public function beforeClass():Void
	{
	}
	
	@AfterClass
	public function afterClass():Void
	{
	}
	
	@Before
	public function setup():Void
	{
	}
	
	@After
	public function tearDown():Void
	{
	}
	
	/**
	  * Make sure the interface has all the methods in the remoting
	  * class with a @remote metadata label.
	  */
	@Test
	public function testBuildingRemotingInterface():Void
	{
		var meta = haxe.rtti.Meta.getFields(RemotingManager);
		Assert.notNull(meta);
		var totalRemotingFields = 0;
		for (fieldName in Type.getInstanceFields(RemotingManager)) {
			if (Reflect.hasField(meta, fieldName) && Reflect.hasField(Reflect.field(meta, fieldName), "remote")) {
				Assert.isTrue(Type.getInstanceFields(BuiltRemotingService).has(fieldName));
				totalRemotingFields++;
			}
		}
		Assert.isTrue(totalRemotingFields == 2);
		
	}
	
	// @AsyncTest
	// public function testAsyncExample(factory:AsyncFactory):Void
	// {
	// 	var handler:Dynamic = factory.createHandler(this, onTestAsyncExampleComplete, 300);
	// 	timer = Timer.delay(handler, 200);
	// }
	
	// private function onTestAsyncExampleComplete():Void
	// {
	// 	Assert.isFalse(false);
	// }
	
	
	// /**
	// * test that only runs when compiled with the -D testDebug flag
	// */
	// @TestDebug
	// public function testExampleThatOnlyRunsWithDebugFlag():Void
	// {
	// 	Assert.isTrue(true);
	// }

}