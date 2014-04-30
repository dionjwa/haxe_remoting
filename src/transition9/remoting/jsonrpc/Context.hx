package transition9.remoting.jsonrpc;

import haxe.Json;

import transition9.remoting.jsonrpc.RPC;

#if !macro
	#if nodejs
		import js.node.WebSocketServer;
	#end
#end

class Context
{
	public function new ()//(connection :RPCConnection)
	{
		// _connection = connection;
		_methods = new Map();
	}

	public function dispose()
	{
		_methods = null;
	}

	public function registerService(service :Dynamic)
	{
		var type = Type.getClass(service);
		var m = haxe.rtti.Meta.getFields(type);
		for (fieldName in Reflect.fields(m)) {
			var fieldData = Reflect.field(m, fieldName);
			if (Reflect.hasField(fieldData, "remote")) {
				var methodName = Type.getClassName(type) + "." + fieldName;
				var method = Reflect.field(service, fieldName);
				var fieldNameLocal = fieldName;
				var argumentCount = Reflect.hasField(fieldData, "arguments") ? Reflect.field(fieldData, "arguments")[0] : -1;
				bindMethod(service, fieldName, argumentCount);
			}
		}
	}

	function bindMethod(service :Dynamic, fieldName :String, ?argumentCount :Int = -1)
	{
		var type = Type.getClass(service);
		var methodName = Type.getClassName(type) + "." + fieldName;
		var method = Reflect.field(service, fieldName);
		Log.info('Registering RPC: $methodName');
		_methods.set(methodName, function(request :RequestDef, callback :ResponseError->Dynamic->Void) {
			if (request.params == null) {
				request.params = [];
			}
			if (argumentCount > 0) {
				request.params[argumentCount - 1] = callback;
			} else {
				//Don't know how many args, hope the request has the right amount
				request.params.push(callback);
			}

			Log.info('Reflect.callMethod(service, "$methodName" request=${request}');
			Reflect.callMethod(service, method, request.params);
		});
	}

	public function handleRequest(clientConnection :WebSocketConnection, request:RequestDef)
	{
		Log.info('handleRequest $request');
		if (_methods.exists(request.method)) {
			var call = _methods.get(request.method);
			Log.info('calling $call');
			call(request,
				function(err :ResponseError, result :Dynamic) {
					Log.info('$request response=$result err=$err');
					var response :ResponseDef = {
						id :request.id,
						result: result,
						error: err
					};
					if (clientConnection.connected) {
						Log.info('Sending to client=$response');
						clientConnection.sendUTF(Json.stringify(response));
					} else {
						Log.error("On request response clientConnection.connected==false. response=" + Json.stringify(request));
					}
				});
		} else {
			Log.error('No registered method="${request.method}"');
		}
	}

	// var _connection :RPCConnection;
	var _methods :Map<String, RequestDef->(ResponseError->Dynamic->Void)->Void>;
}