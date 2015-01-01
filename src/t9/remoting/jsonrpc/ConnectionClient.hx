package t9.remoting.jsonrpc;

import haxe.remoting.JsonRPC;

interface ConnectionClient
{
	public function addResponseListener(onResponse :ResponseDef->Void) : {dispose:Void->Void};
	public function sendRequest(request :RequestDef) :Void;
	public function sendRequests(requests :Array<RequestDef>) :Void;
}