/*******************************************************************************
 * Hydrax: haXe port of the PushButton Engine
 * Copyright (C) 2010 Dion Amago
 * For more information see http://github.com/dionjwa/Hydrax
 *
 * This file is licensed under the terms of the MIT license, which is included
 * in the License.html file at the root directory of this SDK.
 ******************************************************************************/
package transition9.remoting;

typedef StdType = Type;

#if macro
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;
import haxe.macro.Compiler;
#end

using Lambda;
using StringTools;

/**
  * Macros for creating remoting proxy classes from the remoting class or 
  * remoting interfaces.
  */
class Macros
{
	/**
	 * Usage:
	 * 
     * @:build(haxe.remoting.Macros.remotingClass())
     * class YourServerRemotingClass {
     *
     * This will add the following static var fields to the class:
     * REMOTING_INTERFACE: A reference to the dynamically build interface matching the remote
     * 										 methods (functions with the @remote metadata) of this class
     * 
     * REMOTING_ID: Used internally by the remoting system.
     * @convertNodeRelayArgs Whether to convert the callback arg to a NoeRelay object.
     */
	@:macro
	public static function remotingClass(?convertNodeRelayArgs :Bool = false) :Array<Field>
	{
		var pos = Context.currentPos();
		var cls = haxe.macro.Context.getLocalClass().get();
		var className = cls.name;
		var fullClassName = cls.pack.join(".") + "." + cls.name;
		var interfacePackageName = getRemotingInterfaceNameFromClassName(fullClassName);
		
		var interfaceTypePath :TypePath = {
			sub: null,
			params: [],
			pack :cls.pack,
			name: getRemotingInterfaceNameFromClassName(cls.name)
		};
		
		// Context.warning("fullClassName:" + fullClassName, pos);
		
		var interfaceType :TypeDefinition = {
			pos :pos,
			params :[],
			pack: interfaceTypePath.pack,
			name: interfaceTypePath.name,
			meta :[],
			kind :TypeDefKind.TDClass(null , [], true),
			isExtern :false,
 			fields :createAsyncProxyMethodsFromClassFile(fullClassName, true, convertNodeRelayArgs)
		};
		
		// Context.warning("created methods: " + createAsyncProxyMethodsFromClassFile(fullClassName, true, convertNodeRelayArgs).length, pos);
		
		Context.defineType(interfaceType); //Create the remoting manager interface.
		
		var code = "{"
			+ "var public__static__" + RemotingUtil.REMOTING_INTERFACE_NAME + " = " + interfacePackageName + ";" 
			+ 	'var public__static__' + RemotingUtil.REMOTING_ID_NAME + ' = "' + RemotingUtil.getRemotingIdFromManagerClassName(className) + '";'
			+ "}";
		
		var fields = flambe.util.Macros.buildFields(Context.parse(code, pos));
		
		return haxe.macro.Context.getBuildFields().concat(fields);
	}
	
	/**
     */
	// @:macro
	// public static function getRemotingInterface(classNameExpr: Expr) :Expr
	// {
	// 	var pos =  Context.currentPos();
	// 	var className = getClassNameFromClassExpr(classNameExpr);
	// 	var interfaceName = getRemotingInterfaceNameFromClassName(className);
	// 	// return macro StdType.resolveClass(interfaceName);
	// 	var type = StdType.resolveClass(interfaceName);
	// 	// return macro $type;
	// 	// return {expr: macro type, pos:pos};
	// }
	
	@:macro
	public static function getRemoteProxyClass(classNameExpr: Expr, ?excludeManager :Bool = true) :Expr
	{
		var pos =  Context.currentPos();
		var className = getClassNameFromClassExpr(classNameExpr);
		var proxyClassName = getProxyRemoteClassName(className);
		
		try {
			var x = Context.getType(proxyClassName);
		} catch (e :Dynamic) {
			buildRemoteProxyClassInternal(className, null);
		}
		
		if (excludeManager) {
			// Context.warning("Excluding " + className, pos);
			Compiler.exclude(className);
		}
		
		return createClassConstant(proxyClassName, pos);
	}
	
	/**
	  * Adds all methods from implemented interfaces for a class extending 
	  * net.amago.components.remoting.AsyncProxy
	  */
	@:macro
	public static function addRemoteMethodsToInterfaceFrom(classExpr: Expr, ?convertNodeRelayArgsExpr :Expr) :Array<Field>
	{
		var pos = Context.currentPos();
		
		var convertNodeRelayArgs :Bool = convertNodeRelayArgsExpr == null ? true : switch (convertNodeRelayArgsExpr.expr) {
			case EConst(c):
				switch (c) {
					case CIdent(v):
						v != "false";
					default: true;
				}
					
			default: true;
		}
		
		var className = getClassNameFromClassExpr(classExpr);
		
		var fields = haxe.macro.Context.getBuildFields();
		var newFields = createAsyncProxyMethodsFromClassFile(className, true, convertNodeRelayArgs);
		fields = fields.concat(newFields);
		
		return fields;
	}
	
	/**
	  * Takes a server remoting class and the connection variable, 
	  * and returns an instance of the newly created proxy class.
	  */
	@:macro
	public static function buildAndInstantiateRemoteProxyClass(classExpr: Expr, connectionExpr: Expr, ?implementExpr :Expr) :Expr
	{
		var pos = Context.currentPos();
		
		var className = getClassNameFromClassExpr(classExpr);
		var proxyClassName = getProxyRemoteClassName(className);
		
		//If you're building the proxy, you don't want the remote logic compiled in
		#if client
		Compiler.exclude(className);
		#end
		
		try {
			var proxyType = Context.getType(proxyClassName);
			var typePath :TypePath = {
				sub: null,
				params: [],
				pack: [],
				name: ""
			}
			switch(proxyType) {
				case TInst(typeRef, params):
					typePath.name = typeRef.get().name;
					typePath.pack = typeRef.get().pack;
				default: Context.warning("Type not handled: " + StdType.enumConstructor(proxyType), pos);
			}
			return 
			{
				expr: ENew(typePath, [connectionExpr]), 
				pos:pos
			};
		} catch (e :Dynamic) {
			// Context.warning("e: " + e, pos);
			return buildRemoteProxyClassInternal(className, connectionExpr, implementExpr);
		}
	}
	
	/**
	  * Takes a server remoting class adds the remoting methods to the proxy class.
	  */
	@:macro
	public static function addProxyRemoteMethodsFromClass(classExpr: Expr) :Array<Field>
	{
		var pos = Context.currentPos();
		
		var className = getClassNameFromClassExpr(classExpr);
		var fields = haxe.macro.Context.getBuildFields();
		var newFields = createAsyncProxyMethodsFromClassFile(className, false, true);
		fields = fields.concat(newFields);
		
		return fields;
	}
	
	@:macro
	public static function getRemotingId (classExpr :Expr) :Expr
	{
		var className = getClassNameFromClassExpr(classExpr);
		var remotingId = RemotingUtil.getRemotingIdFromManagerClassName(getClassNameFromClassExpr(classExpr));
		return { expr : EConst(CString(remotingId)), pos : Context.currentPos() };
		
		// var remotingId = RemotingUtil.getRemotingIdFromManagerClassName(getClassNameFromClassExpr(classExpr));
		// return { expr : EConst(CString(remotingId)), pos : Context.currentPos() };
	}
	
	/**
	  * Helper functions
	  */
	#if macro
	static function createAsyncProxyMethodsFromClassFile(remoteClassName : String, 
		?asInterface :Bool = false, 
		?convertNodeRelayToCallbacks :Bool = true,
		?errorAsFirstArg :Bool = false) :Array<Field>
	{
		var pos = Context.currentPos();
		
		var interfacePackageName = getRemotingInterfaceNameFromClassName(remoteClassName);
		
		
		var fields = [];
		var remotingId = RemotingUtil.getRemotingIdFromManagerClassName(remoteClassName);
		
		//Add the constructor
		if (!asInterface) {
			fields.push(createNewFunctionBlock(remotingId, pos));
		}
		
		// Add "var _conn :haxe.remoting.AsyncConnection;"
		if (!asInterface) {
			fields.push(createConnectionField(pos));
		}
		
		var remoteMetaRegex : EReg = ~/^[ \t]*@remote.*/;
		var functionRegex : EReg = ~/[\t ]*(public)?[\t ]*function.*/;
		var interfaceRegex : EReg = ~/.*\n[\t ]*interface[\t ].*/;
		var commentRegex : EReg = ~/[\t ]\/\/.*/;
		var interfaceFunctionExprs = [];
		
		if (remoteClassName == null || remoteClassName.length == 0) {
			Context.error("remoteClassName is empty ", pos);
		}
		
		var path = Context.resolvePath(remoteClassName.split(".").join("/") + ".hx");
		
		// Context.warning("path: " + path, pos);
		
		if (!neko.FileSystem.exists(path)) {
			Context.error("Remoting class '" + remoteClassName + "' does not resolve to a valid path=" + path, pos);
		// } else {
		// 	Context.warning("path: exists" + path, pos);
		}
		
		
		var fileContent = "";
		// open and read file line by line
		var fin = neko.io.File.read(path, false);
		try {
			var lineNum = 0;
			while(!fin.eof()) {
				var str = fin.readLine();
				fileContent += str + "\n";
			}
		}
		catch( ex:haxe.io.Eof ) {}
		fin.close();
		
		var isInterface = interfaceRegex.match(fileContent);
		
		var lines = fileContent.split("\n");
		for (ii in 0...lines.length) {
			// Context.warning("" + lines[ii], pos);
			if (commentRegex.match(lines[ii])) {
				continue;
			}
			
			
			if (functionRegex.match(lines[ii])) {
				if (ii > 0 && (isInterface || ((remoteMetaRegex.match(lines[ii - 1]) || lines[ii].indexOf("@remote") > -1)))) {
					var parserCompatibleLine = lines[ii].replace("@remote", "").replace("public", "") + "{}";
					parserCompatibleLine = parserCompatibleLine.trim().replace(";", "");
					var functionExpr = Context.parse(parserCompatibleLine, pos);
					
					switch(functionExpr.expr) {
						default://Do nothing
						case EFunction(name, f)://f is a Function
							//Function args less the callback
							var functionArgsForBlock = new Array<String>();
							var callBackName :String = "cb";
							var nodeRelayArg = f.args[f.args.length - 1];//FunctionArg
							
							if (nodeRelayArg == null) {
								Context.error("Remote functions must end with a callback or a NodeRelay argument: " + remoteClassName + "." + name, pos);
							}
							//Replace function (..., relay :NodeRelay<Foo>) :Void with:
							//function (..., cb :Foo->Void)
							if (convertNodeRelayToCallbacks) {
								switch (nodeRelayArg.type) {
									case TPath(p)://TypePath
										var nodeRelayParam = p.params[0];//TypeParam
										switch(nodeRelayParam) {
											case TPType(t):
												var nodeRelayToCallback = TParent(
													TFunction(
														[t], 
														TPath({ sub:null, name:"Void", pack:[], params:[] })
													)
												);
												f.args[f.args.length - 1] = {name:"cb", opt: false, value: null, type: nodeRelayToCallback};
											default: Context.error("Unhandled nodeRelayParam", pos);
										}
									default:
								}
							}
							
							//Add the function arg names to the connection call
							if (f.args.length > 1) {
								for (arg in f.args.slice(0, f.args.length - 1)) {
									functionArgsForBlock.push(arg.name);
								}
							}
							
							//Create the function block via parsing a string (too complicated otherwise)
							if (!asInterface) {
								var exprStr = '_conn.resolve("' + name + '").call([' + 
									functionArgsForBlock.join(", ") + ']' + (callBackName != null ? ', ' + callBackName: "") + ')';
								var functionBlock = ExprDef.EBlock([
									haxe.macro.Context.parse(exprStr, pos)
								]);
								Reflect.setField(f, "expr", {expr:functionBlock, pos :pos});
							} else {
								Reflect.setField(f, "expr", null);
							}
							
							var field : Field = {
								name : name, 
								doc : null,
								access : asInterface ? [] : [Access.APublic],
								kind : FieldType.FFun(f),
								pos : pos,
								meta : []
							};
							
							fields.push(field);
					}
				}
			}
		}
		
		// if (!asInterface) {
		// 	var code = "{"
		// 		// + "var public__static__" + RemotingUtil.REMOTING_INTERFACE_NAME + " = " + interfacePackageName + ";" 
		// 		// + 	'var public__static__' + RemotingUtil.REMOTING_ID_NAME + ' = "' + RemotingUtil.getRemotingIdFromManagerClassName(remoteClassName) + '";'
				
		// 		+ "var public__" + RemotingUtil.REMOTING_INTERFACE_NAME + " = " + interfacePackageName + ";" 
		// 		+ 	'var public__' + RemotingUtil.REMOTING_ID_NAME + ' = "' + RemotingUtil.getRemotingIdFromManagerClassName(remoteClassName) + '";'
		// 		+ "}";
			
		// 	fields = fields.concat(flambe.util.Macros.buildFields(Context.parse(code, pos)));
		// }
		
		return fields;
	}
	
	static function buildRemoteProxyClassInternal(className: String, connectionExpr :Expr, ?implementExpr :Expr) :Expr
	{
		var pos = Context.currentPos();
		var proxyClassName = getProxyRemoteClassName(className);
		
		var implement :Array<TypePath> = null;
		if (implementExpr != null) {
			implement = [];
			switch(Context.typeof(implementExpr)) {
				case TType(t, params):
					var path :TypePath = {
						sub : null,
						params : [],
						pack : t.get().pack,
						name : t.get().name.replace("#", "")
					}
					implement.push(path);
				default: 
			}
		}
		
		var newProxyType :haxe.macro.TypeDefinition = {
			pack: proxyClassName.split(".").length > 0 ? proxyClassName.split(".").slice(0, proxyClassName.split(".").length - 1) : [],
			name: proxyClassName.split(".")[proxyClassName.split(".").length - 1],
			pos: pos,
			meta: [],
			params: [],
			isExtern: false,
			kind: haxe.macro.TypeDefKind.TDClass(null, implement, false),
			//Add the proxy methods from the remote class
			fields: createAsyncProxyMethodsFromClassFile(className)
		}
		
		// Context.warning("newProxyType.fields: " + newProxyType.fields.length, pos);
		
		// for (f in newProxyType.fields) {
		// 	Context.warning(f.name, pos);
		// }
		
		Context.defineType(newProxyType);
		
		return 
			{
				expr: ENew(
				{//haxe.macro.TypePath
					sub: null,
					params: [],
					pack: newProxyType.pack,
					name: newProxyType.name
				},[
				connectionExpr]
				), 
			pos:pos
			};
	}
	
	/**
	  * Create a class type constant from a class name.
	  */
	public static function createClassConstant (className :String, pos :Position) :Expr
	{
		var pathTokens = className.split(".");
		
		if (pathTokens.length == 1) {
			return {expr: EConst(CType(className)), pos: pos};
		}
		
		var pathExpr = null;
		
		while (pathTokens.length > 1) {
			if (pathExpr == null) {
				pathExpr = {expr: EConst(CIdent(pathTokens.shift())), pos: pos};
			} else {
				pathExpr = {expr: EField(pathExpr, pathTokens.shift()), pos: pos};
			}
		}
		
		return {
			expr: EType(pathExpr, pathTokens.shift()),
			pos: pos
		}
	}
	
	/**
	  * From foo.bar.SomeManager creates foo.bar.SomeManagerService 
	  */
	public static function getRemotingInterfaceNameFromClassName (managerClassName :String) :String
	{
		var remoteId = managerClassName;
		var tokens = remoteId.split(".");
		remoteId = tokens[tokens.length - 1];
		remoteId = remoteId.substr(0, 1).toUpperCase() + remoteId.substr(1);
		// remoteId += "Service";
		remoteId = "I" + remoteId;
		tokens[tokens.length - 1] = remoteId;
		return tokens.join('.'); 
	}
	
	/**
	 * Creates new block for a remoting proxy. 
	 */
	public static function createNewFunctionBlock (remotingId :String, pos :haxe.macro.Position) :Field
	{
		var exprStr = '_conn = c.resolve("' + remotingId + '")';
			
		var func :haxe.macro.Function = {
			ret: null,
			params: [],
			//The expression contains the call to the context
			expr: {expr: ExprDef.EBlock([haxe.macro.Context.parse(exprStr, pos)]), pos:pos},
			args: [{value:null, opt:false, name:"c", type:ComplexType.TPath({sub:null, params:[], pack:["haxe", "remoting"], name:"AsyncConnection"})}] //<FunctionArg>
		}
		
		return {
			name : "new", 
			doc : null, 
			meta : [],
			access : [Access.APublic],
			kind : FieldType.FFun(func),
			pos : pos 
		}
	}
	
	public static function createConnectionField (pos :Position) :Field
	{
		// Add "var _conn :haxe.remoting.AsyncConnection;"
		return {
			name : "_conn", 
			doc : null, 
			meta : [], 
			access : [Access.APrivate], 
			kind : FVar(TPath({ pack : ["haxe", "remoting"], name : "AsyncConnection", params : [], sub : null }), null), 
			pos : pos 
		};
	}
	
	
	public static function getClassNameFromClassExpr (classNameExpr :Expr) :String
	{
		// Context.warning("classNameExpr=" + classNameExpr, Context.currentPos());
		var drillIntoEField = null;
		var className = "";
		drillIntoEField = function (e :Expr) :String {
			switch(e.expr) {
				case EField(e2, field):
					return drillIntoEField(e2) + "." + field;
				case EConst(c):
					switch(c) {
						case CIdent(s):
							// Context.warning("CIdent=" + s, Context.currentPos());
							return s;
						case CString(s):
							// Context.warning("CString=" + s, Context.currentPos());
							return s;
						default:Context.warning(StdType.enumConstructor(c) + " not handled", Context.currentPos());
							return "";
					}
				default: Context.warning(StdType.enumConstructor(e.expr) + " not handled", Context.currentPos());
					return "";
			}
		}
		
		switch(classNameExpr.expr) {
			case EType(e1, field):
				className = field;
				// Context.warning(className, Context.currentPos());
				switch(e1.expr) {
					case EField(e2, field):
						className = drillIntoEField(e1) + "." + className;
					case EConst(c):
						switch(c) {
							case CIdent(s):
								className = s + "." + className;
							case CString(s):
								className = s + "." + className;
							default:Context.warning(StdType.enumConstructor(c) + " not handled", Context.currentPos());
						}
					default: Context.warning(StdType.enumConstructor(e1.expr) + " not handled", Context.currentPos());
				}
			case EConst(c):
				switch(c) {
					case CIdent(s):
						// Context.warning(s, Context.currentPos());
						className = s;
					case CString(s):
						// Context.warning(s, Context.currentPos());
						className = s;
					case CType(s):
						// Context.warning(s, Context.currentPos());
						className = s;
					default:Context.warning(StdType.enumConstructor(c) + " not handled", Context.currentPos());
				}
			case EField(e, field):
				className = drillIntoEField(e) + "." + field;
			default: Context.warning(StdType.enumConstructor(classNameExpr.expr) + " not handled", Context.currentPos());
		}
		
		// Context.warning("className=" + className, Context.currentPos());
		
		return className;
	}
	
	public static function isInterfaceExpr (typeExpr :Expr) :Bool
	{
		switch(typeExpr.expr) {
			case EType(e1, field):
				switch(Context.typeof(typeExpr)) {
					case TType(t, params):
						return true;
					default: 
						return false;
				}
			default: return false;
		}
	}
	
	public static function getProxyRemoteClassName(className : String) :String
	{
		return className + "Proxy";
	}
	
	#end
}
