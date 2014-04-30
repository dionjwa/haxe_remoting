package transition9.remoting.jsonrpc;

import transition9.remoting.jsonrpc.RPC;

interface ConnectionService
{
	public function addRequestListener(onRequest :RequestDef->(ResponseError->Dynamic->Void)->Void) : {dispose:Void->Void};
	public function sendResponse(response :ResponseDef) :Void;
}