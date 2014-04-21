package demo.devserver;

@:build(transition9.remoting.Macros.remotingClass())
class ExampleRemotingService
{
	public function new ()
	{
	}
	
	@remote
	public function processInput (userInput :Int, cb :Int->Void) :Void
	{
		// #if flambe
		// Log.info("From client got " + userInput +", adding 11 and returning " + (11 + userInput));
		// #else
		trace("info", "From client got " + userInput +", adding 11 and returning " + (11 + userInput));
		// #end
		cb(11 + userInput);
	}
}
