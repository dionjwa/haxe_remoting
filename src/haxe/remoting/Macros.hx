/*******************************************************************************
 * Hydrax: haXe port of the PushButton Engine
 * Copyright (C) 2010 Dion Amago
 * For more information see http://github.com/dionjwa/Hydrax
 *
 * This file is licensed under the terms of the MIT license, which is included
 * in the License.html file at the root directory of this SDK.
 ******************************************************************************/
package haxe.remoting;

typedef StdType = Type;

#if macro
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;
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
	  * Safely share the remoting id without sharing the remoting class
	  */
	@:macro
	public static function getRemotingIdFromClassDef (classExpr: Expr) :Expr
	{
		var className = MacroUtil.getClassNameFromClassExpr(classExpr);
		var remotingId = MacroUtil.getRemotingIdFromClassDef(className);
		return {expr: EConst(CString(remotingId)), pos: Context.currentPos()};
	}
	
	@:macro
	public static function getRemoteProxyClass(classNameExpr: Expr) :Expr
	{
		var pos =  Context.currentPos();
		var className = MacroUtil.getClassNameFromClassExpr(classNameExpr);
		var proxyClassName = MacroUtil.getProxyRemoteClassName(className);
		
		try {
			var x = Context.getType(proxyClassName);
		} catch (e :Dynamic) {
			buildRemoteProxyClassInternal(className, null);
		}
		return MacroUtil.createClassConstant(proxyClassName, pos);
	}
	
	@:macro
	public static function getRemoteProxyClassName(classNameExpr: Expr) :Expr
	{
		var className = MacroUtil.getClassNameFromClassExpr(classNameExpr);
		var proxyClassName = MacroUtil.getProxyRemoteClassName(className);
		return MacroUtil.createClassConstant(proxyClassName, Context.currentPos());
	}
	
	/**
	  * Adds all methods from implemented interfaces for a class extending 
	  * net.amago.components.remoting.AsyncProxy
	  */
	 @:macro
	static function buildAsyncProxyClassFromInterface(interfaceExpr: Expr) :Array<Field>
	{
		var pos = Context.currentPos();
		
		var interfaceName = MacroUtil.getClassNameFromClassExpr(interfaceExpr);
		var interfaceType = Context.getType(interfaceName);
		var remotingId = MacroUtil.getRemotingIdFromClassDef(interfaceName);
		
		var fields = haxe.macro.Context.getBuildFields();
		fields = fields.concat(createAsyncProxyMethodsFromRemoteClassInternal(interfaceName));
		
		return fields;
	}
	
	/**
	  * Takes a server remoting class and the connection variable, 
	  * and returns an instance of the newly created proxy class.
	  */
	@:macro
	public static function buildAndInstantiateRemoteProxyClass(classExpr: Expr, connectionExpr: Expr) :Expr
	{
		var pos = Context.currentPos();
		var className = MacroUtil.getClassNameFromClassExpr(classExpr);
		var proxyClassName = MacroUtil.getProxyRemoteClassName(className);
		
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
			return buildRemoteProxyClassInternal(className, connectionExpr);
		}
	}
	
	@:macro
	public static function buildAndInstantiateRemoteProxyClassFromName(className: String, connectionExpr: Expr) :Expr
	{
		var pos = Context.currentPos();
		var proxyClassName = MacroUtil.getProxyRemoteClassName(className);
		
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
			return buildRemoteProxyClassInternal(className, connectionExpr);
		}
	}
	
	/**
	  * Returns a Class constant.
	  */
	@:macro
	public static function buildRemoteProxyClass(classExpr: Expr, connectionExpr: Expr) :Expr
	{
		
		var pos = Context.currentPos();
		var className = MacroUtil.getClassNameFromClassExpr(classExpr);
		
		buildRemoteProxyClassInternal(className, null);
		var proxyClassName = MacroUtil.getProxyRemoteClassName(className);
		
		return MacroUtil.createClassConstant(proxyClassName, pos);
	}
	
	/**
	  * Adds proxy methods from manager class annotated with @remote
	  * metadata.
	  * The remote class is excluded from compilation.
	  */
	@:macro
	public static function addAsyncProxyMethodsFromRemoteClass(classNameExpr : Expr) :Array<Field>
	{
		var className = MacroUtil.getClassNameFromClassExpr(classNameExpr);
		var fields = haxe.macro.Context.getBuildFields();
		
		//Exclude the manager class from compilation into the client.  Very important.
		var managerClass :Type = haxe.macro.Context.getType(className);
		switch (managerClass) {
			case TInst(classType, params):
				classType.get().exclude();
			default:
		}
		
		var pos = Context.currentPos();
		var fields = haxe.macro.Context.getBuildFields();
		
		var remotingId = MacroUtil.getRemotingIdFromClassDef(className);
		
		//Add the constructor
		fields.push(MacroUtil.createNewFunctionBlock(remotingId, pos));
		
		// Add "var _conn :haxe.remoting.AsyncConnection;"
		fields.push(MacroUtil.createConnectionField(pos));
		
		// Add "public static var REMOTING_ID :String = remotingId;"
		fields.push({
			name : "REMOTING_ID", 
			doc : null, 
			meta : [], 
			access : [Access.AStatic, Access.APublic], 
			kind : FVar(
				TPath(
					{ 
						pack : [], 
						name : "String", 
						params : [], 
						sub : null
					}), 
					{ 
						expr : EConst(CString(remotingId)), 
						pos : pos
					}), 
			pos : pos 
		});
		
		var remoteMetaRegex : EReg = ~/^[ \t]@remote.*/;
		var functionRegex : EReg = ~/^[ \t]*(@remote)?[\t ]*public[\t ]+function[ \t]+.*:[\t ]*Void[\t ]*$/;
		var interfaceFunctionExprs = [];
		
		var path = Context.resolvePath(className.split(".").join("/") + ".hx");
		
		var lines = neko.io.File.getContent(path).split("\n");
		for (ii in 0...lines.length) {
			if (functionRegex.match(lines[ii])) {
				if (ii > 0 && (remoteMetaRegex.match(lines[ii - 1]) || lines[ii].indexOf("@remote") > -1)) {
					var parserCompatibleLine = lines[ii].replace("@remote", "").replace("public", "") + "{}";
					var functionExpr = Context.parse(parserCompatibleLine, pos);
					
					switch(functionExpr.expr) {
						default://Do nothing
						case EFunction(name, f)://f is a Function
							//Function args less the callback
							var functionArgsForBlock = new Array<String>();
							var callBackName :String = null;
							for (arg in f.args) {
								switch(arg.type) {
									case TFunction(args, ret)://Ignore the callbacks
										callBackName = arg.name;
									default: //add the rest
										functionArgsForBlock.push(arg.name);
								}
							}
							
							//Create the function block via parsing a string (too complicated otherwise)
							var exprStr = '_conn.resolve("' + name + '").call([' + 
								functionArgsForBlock.join(", ") + ']' + (callBackName != null ? ', ' + callBackName: "") + ')';
							var functionBlock = ExprDef.EBlock([
								haxe.macro.Context.parse(exprStr, pos)
							]);
							Reflect.setField(f, "expr", {expr:functionBlock, pos :pos});
							
							var field :Field = {
								name : name, 
								doc :null,
								access:[Access.APublic],
								kind :FieldType.FFun(f),
								pos : pos,
								meta :[]
							};
							
							fields.push(field);
					}
				}
			}
		}
		return fields;
	}
	
	@:macro
	public static function getRemotingId (managerClass :Class<Dynamic>) :Expr
	{
		var remotingId = StdType.getClassName(managerClass).split(".")[StdType.getClassName(managerClass).split(".").length - 1];
		var pos = haxe.macro.Context.currentPos();
		return { expr : EConst(CString(remotingId)), pos : pos };
	}
	
	/**
	  * Builds all methods from implemented interfaces for a class extending 
	  * net.amago.components.remoting.AsyncProxy
	  */
	@:macro
	public static function addAsyncProxyMethods2(managerClassName :String) :Array<Field>
	{
		var pos = Context.currentPos();
		
		var fields = haxe.macro.Context.getBuildFields();
		
		// Add "var _conn :haxe.remoting.AsyncConnection;"
		fields.push({
			name : "_conn", 
			doc : null, 
			meta : [], 
			access : [Access.APublic], 
			kind : FVar(TPath({ pack : ["haxe", "remoting"], name : "AsyncConnection", params : [], sub : null }), null), 
			pos : pos 
		});
		
		var remotingId = MacroUtil.getRemotingIdFromClassDef(managerClassName);
		// Add "public static var REMOTING_ID :String = remotingId;"
		fields.push({
			name : "REMOTING_ID", 
			doc : null, 
			meta : [], 
			access : [Access.AStatic, Access.APublic], 
			kind : FVar(
				TPath(
					{ 
						pack : [], 
						name : "String", 
						params : [], 
						sub : null
					}), 
					{ 
						expr : EConst(CString(remotingId)), 
						pos : pos
					}), 
			pos : pos 
		});
		
		fields.push(MacroUtil.createNewFunctionBlock(remotingId, pos));
		
		//Add methods annotated with @remote to the client proxy
		var managerClass :Type = haxe.macro.Context.getType(managerClassName);
		switch (managerClass) {
			case TInst(classType, params):
				//Search for fields with @remote metadata, and add them to the proxy
				//typedef haxe.macro.ClassField
				for (f in classType.get().fields.get()) {
					var field :haxe.macro.ClassField = f;
					//Ignore non-remote methods
					if (!field.meta.has("remote")) {
						continue;
					}
					
					var args = null;//:Array<{t: Type, opt: Bool, name: String}>
					var returnType :Type = null;
					//Ignore non-method fields
					if (StdType.enumConstructor(field.type) == "TFun") {
						
					}
					switch(field.type) {
						case TFun(a, r): 
							args = a;
							returnType = r;
						case TLazy(a):	
							Context.warning("TLazy: " + Std.string(a), pos);
						default:
							Context.warning("ignoring " + field.name + ",  " + field.type, pos);		
					}
					
					var func :haxe.macro.Function = {
						ret: null,
						params: [],
						//The expression contains the call to the context
						expr: {expr: ExprDef.EBlock([]), pos:pos},
						args: []
					}
					
					//Create the method, add it to the proxy
					//Function args less the callback
					// Context.warning("adding field=" + field.name, pos);
					fields.push({
						name : field.name, 
						doc : null, 
						meta : [],
						access : [Access.APublic],
						kind : FieldType.FFun(func),
						pos : pos 
					});
				}
			default: Context.warning("wrong type=" + managerClass, pos); 
		}
		
		return fields;
	}
	
	/**
	  * Helper functions
	  */
	#if macro
	public static function createAsyncProxyMethodsFromRemoteClassInternal(remoteClassName : String) :Array<Field>
	{
		var pos = Context.currentPos();
		var fields = [];
		
		var remotingId = MacroUtil.getRemotingIdFromClassDef(remoteClassName);
		
		//Add the constructor
		fields.push(MacroUtil.createNewFunctionBlock(remotingId, pos));
		
		// Add "var _conn :haxe.remoting.AsyncConnection;"
		fields.push(MacroUtil.createConnectionField(pos));
		
		var remoteMetaRegex : EReg = ~/^[ \t]@remote.*/;
		var functionRegex : EReg = ~/^[\t ]*(public)?[\t ]*function.*/;
		var interfaceRegex : EReg = ~/.*\n[\t ]*interface[\t ].*/;
		var interfaceFunctionExprs = [];
		
		var path = Context.resolvePath(remoteClassName.split(".").join("/") + ".hx");
		
		if (!neko.FileSystem.exists(path)) {
			Context.error("Remoting class '" + remoteClassName + "' does not resolve to a valid path=" + path, pos);
		}
		
		var fileContent = neko.io.File.getContent(path);
		
		var isInterface = interfaceRegex.match(fileContent);
		
		var lines = fileContent.split("\n");
		for (ii in 0...lines.length) {
			
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
							// Context.warning("nodeRelayArg=" + nodeRelayArg, pos);
							//Replace function (..., relay :NodeRelay<Foo>) :Void with:
							//function (..., cb :Foo->Void)
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
								default: //Context.error("Last function arg must be a NodeRelay<Foo>", pos);
							}
							
							
							//Add the function arg names to the connection call
							if (f.args.length > 1) {
								for (arg in f.args.slice(0, f.args.length - 1)) {
									functionArgsForBlock.push(arg.name);
								}
							}
							
							//Create the function block via parsing a string (too complicated otherwise)
							var exprStr = '_conn.resolve("' + name + '").call([' + 
								functionArgsForBlock.join(", ") + ']' + (callBackName != null ? ', ' + callBackName: "") + ')';
							var functionBlock = ExprDef.EBlock([
								haxe.macro.Context.parse(exprStr, pos)
							]);
							Reflect.setField(f, "expr", {expr:functionBlock, pos :pos});
							
							var field :Field = {
								name : name, 
								doc :null,
								access:[Access.APublic],
								kind :FieldType.FFun(f),
								pos : pos,
								meta :[]
							};
							
							fields.push(field);
					}
				}
			}
		}
		return fields;
	}
	
	static function excludeClass (className) :Void
	{
		var managerClass :Type = haxe.macro.Context.getType(className);
		switch (managerClass) {
			case TInst(classType, params):
				classType.get().exclude();
			default:
		}
	}
	
	public static function buildRemoteProxyClassInternal(className: String, connectionExpr :Expr) :Expr
	{
		var pos = Context.currentPos();
		var proxyClassName = MacroUtil.getProxyRemoteClassName(className);
		
		//Create the class type
		var newProxyType :haxe.macro.TypeDefinition = {
			pos: pos,
			params: [],
			pack: proxyClassName.split(".").length > 0 ? proxyClassName.split(".").slice(0, proxyClassName.split(".").length - 1) : [],
			name: proxyClassName.split(".")[proxyClassName.split(".").length - 1],
			meta: [],
			kind: haxe.macro.TypeDefKind.TDClass(null, null, false),
			isExtern: false,
			//Add the proxy methods from the remote class
			fields: createAsyncProxyMethodsFromRemoteClassInternal(className)
		}
		
		Context.defineType(newProxyType);
		
		//Exclude from compilation on the client
		excludeClass(className);
		
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
	#end
}
