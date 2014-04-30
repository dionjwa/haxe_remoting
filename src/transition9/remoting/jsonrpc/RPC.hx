package transition9.remoting.jsonrpc;

//http://www.jsonrpc.org/specification

typedef RequestDef = {
	@:optional
	var id :Dynamic;

	var method :String;

	@:optional
	var params :Array<Dynamic>;

	@:optional //It's technically not optional but we'll implement it later
	var jsonrpc :String;
}

typedef ResponseError = {
	var code :Int;
	var message :String;
	@:optional
	var data :Dynamic;
}

typedef ResponseDef = {
	@:optional
	var id :Dynamic;

	@:optional
	var result :Dynamic;

	@:optional
	var error :ResponseError;

	@:optional //It's technically not optional but we'll implement it later
	var jsonrpc :String;
}
