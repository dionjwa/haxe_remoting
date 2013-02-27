package transition9.websockets;

import haxe.Unserializer;

#if !macro
	#if nodejs
	import js.Node;
	#end
#end

typedef JsonMessage = {
	//Message id. Used for message handling
	@:optional
	var id :String;
	//Message version.  Older clients may exist in the wild.
	var ver :Int;
}

class Messages
{
	public static function decodeHaxeMessage <T>(message :String) :T
	{
		#if !macro
			try {
				return Unserializer.run(message.substr(Constants.PREFIX_HAXE_OBJECT.length));
			} catch (e :Dynamic) {
				Log.error("Error parsing haxe object: " + message + ", e=" + e);
				return null;
			}
		#else
			return null;
		#end
	}
	
	public static function decodeJsonMessage <T>(message :String) :T
	{
		#if !macro
			try {
				#if nodejs
				return Node.parse(message.substr(0, Constants.PREFIX_HAXE_JSON.length));
				#elseif html5
				return JSON.parse(message.substr(0, Constants.PREFIX_HAXE_JSON.length));
				#end
			} catch (e :Dynamic) {
				Log.error("Error parsing json object: " + message + ", e=" + e);
				return null;
			}
		#else
			return null;
		#end
	}
}
