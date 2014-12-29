package transition9.remoting;

import js.Node;
import js.node.Mime;

/**
 * Single static function for serving all kinds of file types.
 */

 class ServeFile
 {
 	public static function serveFile(request :NodeHttpServerReq, response :NodeHttpServerResp) :Void
 	{
 		var mime :Mime = Node.require('mime');
 		var uri = Node.url.parse(request.url).pathname;
 		var filename = Node.path.join(Node.process.cwd(), uri);
 		Node.fs.exists(filename, function(exists) {
 			if (!exists) {
 				response.writeHead(404, {"Content-Type": "text/plain"});
 				response.write("404 Not Found\n");
 				response.end();
 			}

 			if (Node.fs.statSync(filename).isDirectory()) filename += '/index.html';

 			Node.fs.readFile(filename, "binary", function(err, file) {
 				if (err) {
 					response.writeHead(500, {"Content-Type": "text/plain"});
 					response.write(err + "\n");
 					response.end();
 				}
 				var contentType = mime.lookup(filename);
 				console.log(filename + ':' + contentType);

 				response.writeHead(200, {"Content-Type": contentType});
 				response.write(file, "binary");
 				response.end();
			});
		});
 	}
 }