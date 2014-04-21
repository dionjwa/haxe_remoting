/*******************************************************************************
 * Hydrax: haXe port of the PushButton Engine
 * Copyright (C) 2010 Dion Amago
 * For more information see http://github.com/dionjwa/Hydrax
 *
 * This file is licensed under the terms of the MIT license, which is included
 * in the License.html file at the root directory of this SDK.
 ******************************************************************************/
package transition9.remoting;

#if !(nodejs || nodejs_std)
#error
#end

import haxe.remoting.Context;

import js.Node;

using StringTools;
/** 
  * You can use e.g. [baseurl]/serviceName/apifunction?arg1=foo&arg2=314
  * for calling your API as well as the regular haxe remoting calls.  Useful for 
  * testing in the browser. Returns json instead of a haxe object.
  * Node the lower case of the serviceName.
  * TODO: check if there is a valid service, returning false if not.  Currently always returns true.
  */
class NodeJsHtmlConnectionJsonFallback extends NodeJsHtmlConnection
{
	public function new (ctx :Context)
	{
		super(ctx);
	}

	override public function handleRequest (req :NodeHttpServerReq, res :NodeHttpServerResp) :Bool 
	{
		if (super.handleRequest(req, res)) {
			return true;
		} else {
			return handleJsonRequest(req, res);
		}
	}

	public function handleJsonRequest (req :NodeHttpServerReq, res :NodeHttpServerResp) :Bool 
	{
		res.setHeader("Content-Type", "application/json");
		req.addListener("end", function() {
			req.removeAllListeners("end");
			try {
				var parsedUrl = Node.url.parse(req.url, true);
				var path = parsedUrl.pathname.substr(1).split("/");
				var args :Array<Dynamic> = [];
				try {
					if (parsedUrl != null) {

						if (parsedUrl.query != null) {
							var keys = [];
							for(key in Reflect.fields(parsedUrl.query)) {
								if (key.startsWith("arg")) {
									keys.push(key);
								}
							}
							keys.sort(compareStrings);
							for(key in keys) {
								args.push(Reflect.field(parsedUrl.query, key));
							}
							//Try to convert args to the right type.  Only simple args work
							for (i in 0...args.length) {
								var x :Float = Std.parseFloat(args[i]);
								if (Math.isNaN(x)) {
									var z :Int = Std.parseInt(args[i]);
									if (!Math.isNaN(x)) {
										args[i] = x;
									}
								} else {
									args[i] = x;
								}
							}
						}
					}
				} catch (e :Dynamic) {
					#if flambe
						Log.error(e);
					#else
						trace(e);
					#end
				}

				res.writeHead(200);
				var cb = function (data :Dynamic) {
					res.end('{"status": "success",  "result": ' + Node.stringify(data) + '}');
				};
				args.push(cb);
				_context.call(path, args);
			} catch (e :Dynamic) {
				var message = (e.message != null) ? e.message : e;
				var stack = e.stack;

				#if flambe
				Log.error("Remoting exception: " +
					(e.stack != null ? e.stack : message));
				#else
				trace("Remoting exception: " +
					(e.stack != null ? e.stack : message));
				#end
				res.writeHead(200);
				res.end('{"status": "error",  "error": "' + message + '"}');
			}
		});
		return true;
	}

	private static function compareStrings(a :String, b :String) :Int 
	{
		a = a.toLowerCase();
		b = b.toLowerCase();
		if (a < b) return -1;
		if (a > b) return 1;
		return 0;
	}
}
