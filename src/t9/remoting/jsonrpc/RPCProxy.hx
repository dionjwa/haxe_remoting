package t9.remoting.jsonrpc;

import t9.remoting.jsonrpc.RPC;

import tink.core.Outcome;

class RPCProxy
{
	public function new(conn :ConnectionClient)
	{
		_conn = conn;
		_disposables = [];
		_callbacks = new Map<Int, ResponseError->Dynamic->Void>();
		_className = Type.getClassName(Type.getClass(this));
		_disposables.push(_conn.addResponseListener(function(response :ResponseDef) {
			onResponse(response);
		}));
	}

	public function dispose()
	{
		// Log.info("RPCProxy.dispose");
		if (_disposables != null) {
			for (disposable in _disposables) {
				disposable.dispose();
			}
			_disposables = null;
		}
	}

	public function removeCallback(id :Int)
	{
		return _callbacks.remove(id);
	}

	function call(methodName :String, args :Array<Dynamic>, ?cb :ResponseError->Dynamic->Void) :Int
	{
		// Log.info('RPCProxy.call("$methodName", $args, $cb)');
		var request :RequestDef = {
			id: CALLBACK_IDS++,
			method: methodName,
			params: args
		};
		if (cb != null) {
			_callbacks.set(request.id, cb);
		}
		// Log.info('RPCProxy.sending($request)');
		_conn.sendRequest(request);
		return request.id;
	}

	function onResponse(response :ResponseDef)
	{
		if (_callbacks.exists(response.id)) {
			var cb = _callbacks.get(response.id);
			_callbacks.remove(response.id);
			cb(response.error, response.result);
		} else {
			Log.error('No callback for response=$response');
		}
	}

	var _className :String;
	var _conn :ConnectionClient;
	var _callbacks :Map<Int, ResponseError->Dynamic->Void>;
	var _disposables :Array<{dispose:Void->Void}>;

	static var CALLBACK_IDS :Int = 0;//Unique to client
}