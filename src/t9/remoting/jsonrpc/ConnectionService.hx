package t9.remoting.jsonrpc;

import haxe.remoting.JsonRPC;

interface ConnectionService
{
	public function addRequestListener(onRequest :RequestDef->(ResponseError->Dynamic->Void)->Void) : {dispose:Void->Void};
	public function sendResponse(response :ResponseDef) :Void;
}