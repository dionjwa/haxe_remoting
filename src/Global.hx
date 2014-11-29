/**
 * Convenience abstract for dealing with the global object.
 * Javascript specific now, but can be easily extended for xplat.
 */

abstract Global ({}){

 	static public inline function object() :Global
 	{
#if js
	#if nodejs
		return untyped __js__('global');
	#else
		return untyped __js__('window');
	#end
#else
		throw "Not sure what the global object is on this platform";
#end
 	}

    @:arrayAccess public inline function arrayAccess(key:Dynamic) :Dynamic
    {
#if js
        return untyped this[key];
#else
		return Reflect.field(this, key);
#end
    }

    @:arrayAccess public inline function arrayWrite<T>(key:Dynamic, value:Dynamic)
    {
#if js
        untyped this[key] = value;
#else
		Reflect.setField(this, key, value);
#end
    }

#if cocos2dx
        public var isCocosInitialized (get, set) :Bool;
        inline function get_isCocosInitialized() :Bool
        {
    #if js
            return untyped this["hx_isCocosInitialized"] == true;
    #else
    		return Reflect.field(this, "hx_isCocosInitialized") == true;
    #end
        }
    	inline function set_isCocosInitialized(value :Bool) :Bool
        {
    #if js
            untyped this["hx_isCocosInitialized"] = value;
    #else
    		Reflect.setField(this, "hx_isCocosInitialized", value);
    #end
    		return value;
        }

        public var serverAddress (get, set) :String;
        inline function get_serverAddress() :String
        {
    #if js
            return untyped this["hx_serverAddress"];
    #else
            return Reflect.field(this, "hx_serverAddress");
    #end
        }
        inline function set_serverAddress(value :String) :String
        {
    #if js
            untyped this["hx_serverAddress"] = value;
    #else
            Reflect.setField(this, "hx_serverAddress", value);
    #end
            return value;
        }
#end
}