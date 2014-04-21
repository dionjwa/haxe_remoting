package transition9.remoting;

using StringTools;

class RemotingUtil
{
	public static var REMOTING_ID_NAME = "REMOTING_ID";
	public static var REMOTING_INTERFACE_NAME = "REMOTING_INTERFACE";

	/**
	  * Creates a remoting id from a manager class name. E.g.: 
	  * 'FooManager' will become 'fooService'.
	  * 'MyClass' will become 'myClassService'.
	  * 'SomeService' will become 'someService'.
	  * @managerClassName The class name of the class built with @:build(transition9.remoting.Macros	.remotingClass())
	  */
	public static function getRemotingIdFromManagerClassName (managerClassName :String) :String
	{
		//Removes any instances of "Manager" or "Service" and appends "Service".
		//E.g. "PlayerDataManager" would become "PlayerDataService"
		//E.g. "TestThing" would become "TestThingService"
		if (managerClassName.lastIndexOf(".") > 0) {
			managerClassName = managerClassName.substr(managerClassName.lastIndexOf(".") + 1);
		}
		var remotingId = managerClassName.replace("Manager", "").replace("Service", "") + "Service";
		return remotingId.substr(0, 1).toLowerCase() + remotingId.substr(1);
	}
}
