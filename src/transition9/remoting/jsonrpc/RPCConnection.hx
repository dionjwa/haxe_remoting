package transition9.remoting.jsonrpc;

import transition9.remoting.jsonrpc.RPC;

interface RPCConnection
{
	public var onResponse :ResponseDef->Void;
	public function sendRequest(request :RequestDef) :Void;
	public function sendRequests(requests :Array<RequestDef>) :Void;
}