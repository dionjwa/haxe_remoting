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
		
		var className = MacroUtil.getClassNameFromClassExpr(classExpr);
		
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
		
		var className = MacroUtil.getClassNameFromClassExpr(classExpr);
		var fields = haxe.macro.Context.getBuildFields();
		var newFields = createAsyncProxyMethodsFromClassFile(className, false, true);
		fields = fields.concat(newFields);
		
		return fields;
	}
	
	@:macro
	public static function getRemotingId (classExpr :Expr) :Expr
	{
		var remotingId = MacroUtil.getRemotingIdFromManagerClassName(MacroUtil.getClassNameFromClassExpr(classExpr));
		return { expr : EConst(CString(remotingId)), pos : Context.currentPos() };
	}
	
	/**
	  * Helper functions
	  */
	#if macro
	static function createAsyncProxyMethodsFromClassFile(remoteClassName : String, 
		asInterface :Bool = false, convertNodeRelayToCallbacks :Bool = true) :Array<Field>
	{
		var pos = Context.currentPos();
		
		var fields = [];
		
		var remotingId = MacroUtil.getRemotingIdFromManagerClassName(remoteClassName);
		
		//Add the constructor
		if (!asInterface) {
			fields.push(MacroUtil.createNewFunctionBlock(remotingId, pos));
		}
		
		// Add "var _conn :haxe.remoting.AsyncConnection;"
		if (!asInterface) {
			fields.push(MacroUtil.createConnectionField(pos));
		}
		
		var remoteMetaRegex : EReg = ~/^[ \t]*@remote.*/;
		var functionRegex : EReg = ~/[\t ]*(public)?[\t ]*function.*/;
		var interfaceRegex : EReg = ~/.*\n[\t ]*interface[\t ].*/;
		var interfaceFunctionExprs = [];
		
		if (remoteClassName == null || remoteClassName.length == 0) {
			Context.error("remoteClassName is empty ", pos);
		}
		
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
		return fields;
	}
	
	static function buildRemoteProxyClassInternal(className: String, connectionExpr :Expr, ?implementExpr :Expr) :Expr
	{
		var pos = Context.currentPos();
		var proxyClassName = MacroUtil.getProxyRemoteClassName(className);
		
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
	#end
}
