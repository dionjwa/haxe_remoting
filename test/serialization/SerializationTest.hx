package serialization;

import serialization.support.RedisSerializableClass;
import haxe.serialization.Serialization;
import utest.Assert;

using Lambda;

/**
 * Serialization tests
 */
class SerializationTest 
{
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
	  * Redis can store objects as hashes (key, values).
	  */
	@Test
	public function testRedisSerialization():Void
	{
		var toSerialize = new RedisSerializableClass();
		
		var var1 = "someTestString";
		var var2 = 7;
		
		
		toSerialize.var1 = var1;
		toSerialize.var2 = var2;
		
		var array = Serialization.classToArray(toSerialize);
		
		Assert.isTrue(array.length == 4);
		
		var deserialized :RedisSerializableClass = Serialization.arrayToClass(array, RedisSerializableClass);
		
		Assert.isTrue(toSerialize.var1 == deserialized.var1);
		Assert.isTrue(toSerialize.var2 == deserialized.var2);
		
	}
}
