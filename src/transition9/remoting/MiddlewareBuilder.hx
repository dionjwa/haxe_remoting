package transition9.remoting;

import haxe.remoting.Context;

import js.node.Connect;
import js.Node;

using StringTools;

class MiddlewareBuilder
{
	//The context holds all the different api/services.
	var _context :Context;
	var _serviceHandler :NodeJsHtmlConnection;
	
	public function new ()
	{
		_context = new Context();
		_serviceHandler = new NodeJsHtmlConnection(_context);
	}
	
	public function allowJsonFallback () :MiddlewareBuilder
	{
		_serviceHandler = new NodeJsHtmlConnectionJsonFallback(_context);
		return this;	
	}
	
	public function addRemotingManager (remotingInstance :Dynamic) :MiddlewareBuilder
	{
		_context.addObject(
			Reflect.field(Type.getClass(remotingInstance), RemotingUtil.REMOTING_ID_NAME), 
			remotingInstance);
		return this;
	}
	
	public function buildConnectMiddleware () :NodeHttpServerReq->NodeHttpServerResp->(Void->MiddleWare)->Void
	{
		var basicHandler = buildBasicHandler();
		return function (req :NodeHttpServerReq, res :NodeHttpServerResp, next :Void->MiddleWare) :Void {
			if (!basicHandler(req, res)) {
				next();
			}
		}
	}
	
	public function buildBasicHandler () :NodeHttpServerReq->NodeHttpServerResp->Bool
	{
		return function (req :NodeHttpServerReq, res :NodeHttpServerResp) :Bool {
			//Will return false if the request is not a remoting call.
			return _serviceHandler.handleRequest(req, res);
		}
	}
}
