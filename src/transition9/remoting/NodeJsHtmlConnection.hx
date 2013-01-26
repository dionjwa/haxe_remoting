/*******************************************************************************
 * Hydrax: haXe port of the PushButton Engine
 * Copyright (C) 2010 Dion Amago
 * For more information see http://github.com/dionjwa/Hydrax
 *
 * This file is licensed under the terms of the MIT license, which is included
 * in the License.html file at the root directory of this SDK.
 ******************************************************************************/
package transition9.remoting;

#if !nodejs
#error
#end

import haxe.remoting.Context;

import js.Node;

using StringTools;
/**
  * Haxe HTTP remoting connection for Node.js
  * Used with AsyncProxy
  * for client and server asynchronous communications.
  */
class NodeJsHtmlConnection
{
	var _context :Context;
	/** 
	  * If true, you can use e.g. [baseurl]/serviceName/apifunction?arg1=foo&arg2=314
	  * for calling your API as well as the regular haxe remoting calls.  Useful for 
	  * testing in the browser. Returns json instead of a haxe object.
	  * Node the lower case of the serviceName.
	  */
	var _allowHttpUrlApi :Bool;
	
	public function new (ctx :Context, ?allowHttpUrlApi :Bool = false)
	{
		_allowHttpUrlApi = allowHttpUrlApi;
		_context = ctx;
	}
	
	public function connect (ctx :Context) :Void
	{
		if (_context != null) throw "Context is already set";
		_context = ctx;
	}
	
	public function handleRequest (req :NodeHttpServerReq, res :NodeHttpServerResp) :Bool 
	{
		if (req.method != "POST" || req.headers[untyped "x-haxe-remoting"] != "1") {
			if (_allowHttpUrlApi) {
				return handleJsonRequest(req, res);
			} else {
				return false;
			}
		}
		
		//Get the POST data
		req.setEncoding("utf8");
		var content = "";
		
		req.addListener("data", function(chunk) {
			content += chunk;
		});

		req.addListener("end", function() {
			req.removeAllListeners("data");
			req.removeAllListeners("end");
			
			res.setHeader("Content-Type", "text/plain");
			res.setHeader("x-haxe-remoting", "1");
			res.writeHead(200);
			
			try {
				var cb = function (data :Dynamic) {
					flambe.util.Assert.that(data != null, "data != null");
					res.end("hxr" + haxe.Serializer.run(data));
				};
				var nodeUrl :NodeUrlObj = Node.url.parse(req.url, true);
				var requestData = nodeUrl.query.__x;
				flambe.util.Assert.that(requestData != null, "requestData != null");
				var u = new haxe.Unserializer(requestData);
				var path = u.unserialize();
				var args :Array<Dynamic> = u.unserialize();
				args.push(cb);
				_context.call(path,args);
			} catch (e :Dynamic) {
				var message = (e.message != null) ? e.message : e;
				var stack = e.stack;
				
				#if debug
					//In debug mode, list all available services
					var serviceIds = [];
					var objects :Hash<Dynamic> = cast Reflect.field(_context, "objects");
					for (key in objects.keys()) {
						serviceIds.push(key);
					}
					message = "[Context, services:['" + serviceIds.join("', '") + "']]" + " " + message;
				#end
				
				#if flambe
				Log.error("Remoting exception: " +
					(e.stack != null ? e.stack : message));
				#else
				trace("Remoting exception: " +
					(e.stack != null ? e.stack : message));
				#end
				
				var s = new haxe.Serializer();
				s.serializeException(message);
				res.end("hxr" + s.toString());
			}
		});
		return true;
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
	
	// private static var urlQuery = Node.require("url");
}
