package ;



class Tests
{
	public static function main () :Void
	{
#if mconsole
		Console.start();
#end
		trace("haxe.unit tests:");
#if nodejs
		haxe.unit.TestRunner.print = function(v :Dynamic) :Void { untyped __js__("console.log(v)");};
#end

		var r = new haxe.unit.TestRunner();
		// r.add(new remoting.RemotingTest());
		// your can add others TestCase here
		// finally, run the tests
		r.run();

		trace("async tests:");
#if (nodejs && !travis)
		try {
			untyped __js__("if (require.resolve('source-map-support')) {require('source-map-support').install(); console.log('source-map-support installed');}");
		} catch (e :Dynamic) {}
#end
		var asyncTestClasses :Array<Class<Dynamic>> = new Array<Class<Dynamic>>();
		// asyncTestClasses.push(remoting.RemotingTest);
		asyncTestClasses.push(websockets.WebSocketBasicTest);
		// asyncTestClasses.push(websockets.WebSocketRPCTest);
		transition9.unit.AsyncTestTools.runTestsOn(asyncTestClasses);

	}
}
