package transition9.remoting.jsonrpc;

//http://www.jsonrpc.org/specification
typedef RequestDef = {
	@:optional
	var id :String;

	var method :String;

	@:optional
	var params :Array<Dynamic>;

	@:optional //It's technically not optional but we'll implement it later
	var jsonrpc :String;
}

typedef ResponseDef = {
	@:optional
	var id :String;

	@:optional
	var result :Dynamic;

	@:optional
	var error :ResposeError;

	@:optional //It's technically not optional but we'll implement it later
	var jsonrpc :String;
}

typedef ResposeError = {
	var code :Int;
	var message :String;
	@:optional
	var data :Dynamic;
}