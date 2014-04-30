package transition9.remoting.jsonrpc;

import transition9.remoting.jsonrpc.RPC;

interface ConnectionClient
{
	public function addResponseListener(onResponse :ResponseDef->Void) : {dispose:Void->Void};
	public function sendRequest(request :RequestDef) :Void;
	public function sendRequests(requests :Array<RequestDef>) :Void;
}