package haxe.remoting;

//http://www.jsonrpc.org/specification

typedef JsonRpcMessage = {
	var jsonrpc :String;
}

typedef RequestDef = { > JsonRpcMessage,
	@:optional
	var id :Dynamic;

	var method :String;

	@:optional
	var params :Dynamic;
}

typedef ResponseError = {
	var code :Int;
	var message :String;
	@:optional
	var data :Dynamic;
}

typedef ResponseDef = { > JsonRpcMessage,
	var id :Dynamic;
}

typedef ResponseDefSuccess = { > ResponseDef,
	var result :Dynamic;
}

typedef ResponseDefError = { > ResponseDef,
	var error :ResponseError;
}
