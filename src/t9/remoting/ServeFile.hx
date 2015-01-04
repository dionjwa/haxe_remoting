package t9.remoting;

import js.Node;
import js.node.Mime;

/**
 * Single static function for serving all kinds of file types.
 */
@:expose("ServeUtil")
class ServeFile
{
 	public static function serveDirectory(directoryPath :String) :NodeHttpServerReq->NodeHttpServerResp->Bool
 	{
 		return function(request :NodeHttpServerReq, response :NodeHttpServerResp) :Bool {
 			var uri = Node.url.parse(request.url).pathname.substr(1);
 			var filename = directoryPath == null ? Node.path.join(Node.process.cwd(), uri) : Node.path.join(directoryPath, uri);
 			if(Node.fs.existsSync(filename) && Node.fs.statSync(filename).isFile()) {
 				serveFile(filename, response);
 				return true;
 			} else {
 				return false;
 			}

 		};
 	}

 	public static function serveFileRequest(request :NodeHttpServerReq, response :NodeHttpServerResp, ?pathRoot :String) :Void
 	{
 		var mime :Mime = Node.require('mime');
 		var uri = Node.url.parse(request.url).pathname;
 		var filename = pathRoot == null ? Node.path.join(Node.process.cwd(), uri) : pathRoot + uri;
 		serveFile(filename, response);
 	}

 	public static function serveFile(filePath :String, response :NodeHttpServerResp) :Void
 	{
 		var mime :Mime = Node.require('mime');
 		Node.fs.exists(filePath, function(exists) {
 			if (!exists) {
 				response.writeHead(404, {"Content-Type": "text/plain"});
 				response.write("404 Not Found\n");
 				response.end();
 			}

 			if (Node.fs.statSync(filePath).isDirectory()) filePath += '/index.html';

 			Node.fs.readFile(filePath, {"encoding":null, "flag":"r"}, function(err:NodeErr, data :Dynamic) {
 				if (err != null) {
 					response.writeHead(500, {"Content-Type": "text/plain"});
 					response.write(err + "\n");
 					response.end();
 				}
 				var contentType = mime.lookup(filePath);
 				Log.info("Served=" + filePath + ':' + contentType);

 				response.writeHead(200, {"Content-Type": contentType});
 				response.write(data, "binary");
 				response.end();
			});
		});
 	}
}