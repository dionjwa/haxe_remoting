package foo;

@remoteId("fooService")
interface IRemotingService
{
	@remote
	public function getFoos (cb: Array<String>->Void) :Void;
	
	@remote
	public function getFoo (fooName :String, cb: String->Void) :Void;
}
