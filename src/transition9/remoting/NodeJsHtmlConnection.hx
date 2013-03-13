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
  * Haxe HTTP remoting connection for Node.js
  * Used with AsyncProxy
  * for client and server asynchronous communications.
  */
class NodeJsHtmlConnection
{
	var _context :Context;
	
	public function new (ctx :Context)
	{
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
				return false;
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
				var requestData = req.method == 'POST' ? 
					(content.urlDecode().substr(4)) : (Node.url.parse(req.url, true).query.__x);
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
					#if haxe3
					var objects :Map<String, Dynamic> = cast Reflect.field(_context, "objects");
					#else
					var objects :Hash<Dynamic> = cast Reflect.field(_context, "objects");
					#end
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
}
