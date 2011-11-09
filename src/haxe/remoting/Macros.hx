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
		return MacroUtil.createClassConstant(proxyClassName, pos);
	}
	
	@:macro
	public static function getRemoteProxyClassName(classNameExpr: Expr) :Expr
	{
		var className = MacroUtil.getClassNameFromClassExpr(classNameExpr);
		var proxyClassName = MacroUtil.getProxyRemoteClassName(className);
		return MacroUtil.createClassConstant(proxyClassName, Context.currentPos());
		// return {expr: ExprDef.EConst(Constant.CString(proxyClassName)), pos: Context.currentPos()};
	}
	
	/**
	  * Adds all methods from implemented interfaces for a class extending 
	  * net.amago.components.remoting.AsyncProxy
	  */
	 @:macro
	static function buildAsyncProxyClassFromInterface(interfaceExpr: Expr) :Array<Field>
	{
		var pos = Context.currentPos();
		
		// var className = MacroUtil.getClassNameFromClassExpr(classExpr);
		var interfaceName = MacroUtil.getClassNameFromClassExpr(interfaceExpr);
		var interfaceType = Context.getType(interfaceName);
		
		// Exclude from compilation on the client
		// excludeClass(className);
		
		var remotingId = MacroUtil.getRemotingIdFromClassDef(interfaceName);
		// Context.warning("remotingId=" + remotingId, pos);
		
		var fields = haxe.macro.Context.getBuildFields();
		fields = fields.concat(createAsyncProxyMethodsFromRemoteClassInternal(interfaceName, false));
		//Add constructor
		// fields.push(MacroUtil.createNewFunctionBlock(remotingId, pos));
		// Add "var _conn :haxe.remoting.AsyncConnection;"
		// fields.push(MacroUtil.createConnectionField(pos));
		// Context.warning(interfaceName + " fields " + fields.length, pos);
		// var fields = [];
		
		// var functionRegex : EReg = ~/^[ \t]*function[ \t]*.*/;
		// var interfaceFunctionExprs = [];
		
		// // for (d in classType.interfaces) {
		// 	// var interfaceName = d.t.get().pack.join("/") + "/" + d.t.get().name + ".hx";
		// 	var path = Context.resolvePath(interfaceName.split(".").join("/") + ".hx");
		// 	for (line in neko.io.File.getContent(path).split("\n")) {
		// 		if (functionRegex.match(line)) {
		// 			var parserCompatibleLine = line.replace("Void;", "Void {}");
		// 			var functionExpr = Context.parse(parserCompatibleLine, pos);
		// 			switch(functionExpr.expr) {
		// 				case EFunction(name, f)://f is a Function
		// 					//Function args less the callback
		// 					var functionArgsForBlock = new Array<String>();
		// 					var callBackName :String = null;
		// 					for (arg in f.args) {
		// 						switch(arg.type) {
		// 							case TFunction(args, ret)://Ignore the callbacks
		// 								callBackName = arg.name;
		// 							default: //add the rest
		// 								functionArgsForBlock.push(arg.name);
		// 						}
		// 					}
							
		// 					//Create the function block via parsing a string (too complicated otherwise)
		// 					var exprStr = '_conn.resolve("' + name + '").call([' + 
		// 						functionArgsForBlock.join(", ") + ']' + (callBackName != null ? ', ' + callBackName: "") + ')';
		// 					var functionBlock = ExprDef.EBlock([
		// 						haxe.macro.Context.parse(exprStr, pos)
		// 					]);
		// 					Reflect.setField(f, "expr", {expr:functionBlock, pos :pos});
							
		// 					var field :Field = {
		// 						name : name, 
		// 						doc :null,
		// 						access:[Access.APublic],
		// 						kind :FieldType.FFun(f),
		// 						pos : pos,
		// 						meta :[]
		// 					};
							
		// 					fields.push(field);
							
		// 				default: haxe.macro.Context.warning("Should not be here", pos);
		// 			}
		// 		}
			// }
		// }
		return fields;
	}
	
	/**
	  * Takes a server remoting class and the connection variable, 
	  * and returns an instance of the newly created proxy class.
	  */
	@:macro
	public static function buildRemoteProxyClass(classExpr: Expr, connectionExpr: Expr) :Expr
	{
		
		var pos = Context.currentPos();
		var className = MacroUtil.getClassNameFromClassExpr(classExpr);
		
		// Context.warning("" + connectionExpr, pos);
		
		//Exclude from compilation on the client
		excludeClass(className);
		
		var proxyClassName = MacroUtil.getProxyRemoteClassName(className);
		// Context.warning("proxyClassName=" + proxyClassName, pos);
		
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
		
		// Context.warning("newProxyType=" + newProxyType, pos);
		// Context.warning("newProxyType.name=" + newProxyType.name, pos);
		// Context.warning("newProxyType.pack=" + newProxyType.pack, pos);
		
		Context.defineType(newProxyType);
		
		
		return 
			{
				expr:ENew(
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
		
		// return {expr:EBlock([]), pos:pos};
		// return MacroUtil.createClassConstant(proxyClassName, pos);
	}
	
	/**
	  * Adds proxy methods from manager class annotated with @remote
	  * metadata.
	  * The remote class is excluded from compilation.
	  */
	@:macro
	public static function addAsyncProxyMethodsFromRemoteClass(classNameExpr : Expr) :Array<Field>
	{
		// var drillIntoEField = null;
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
		
		// var managerClassName = StdType.getClassName(managerClass);
		// //Helper functions
		// var convertTypeParamToTypePathParam = null;
		// convertTypeParamToTypePathParam = function (typeParam: Type) :ComplexType {
		// 	switch(typeParam) {
		// 		case TInst(classType, params):
		// 			return ComplexType.TPath(
		// 				{
		// 					sub: null,
		// 					//Array<TypeParam>
		// 					params: classType.get().params.map(function (paramData :{t: Type, name: String}) :TypeParam {
		// 						return TypeParam.TPType(convertTypeParamToTypePathParam(paramData.t));
		// 					}).filter(function (val :Dynamic) :Bool {return val != null;}).array(),
		// 					pack: classType.get().pack,
		// 					name: classType.get().name
		// 				});
		// 		default:
		// 			Context.error("Type param conversion not yet implemented=" + typeParam, Context.currentPos());
		// 	}
		// 	return null;
		// }
		
		
		// var createRemotingFunctionBlock = function (remotingId :String, 
		// 	functionArgs :Array<{ t : Type, opt : Bool, name : String }>, pos :haxe.macro.Position) :ExprDef {
		// 	// Create the function block
		// 	//Function args less the callback
		// 	var functionArgsForBlock = new Array<String>();
		// 	var callBackName :String = null;
		// 	if (functionArgs != null) {
		// 		for (arg in functionArgs) {
		// 			switch(arg.t) {
		// 				case TFun(args, ret)://Ignore the callbacks
		// 					callBackName = arg.name;
		// 				default: //add the rest
		// 					functionArgsForBlock.push(arg.name);
		// 			}
		// 		}
		// 	}
			
		// 	//Create the function block via parsing a string (too complicated otherwise)
		// 	var exprStr = '_conn.resolve("' + remotingId + '").call([' + 
		// 		functionArgsForBlock.join(", ") + ']' + (callBackName != null ? ', ' + callBackName: "") + ')';
		// 	return ExprDef.EBlock([
		// 		haxe.macro.Context.parse(exprStr, pos)
		// 	]);
		// }
	
		
		
		
		// /**
	  // * For getting a NodeRelay<SomeType> and getting the SomeType as a ComplexType 
	  // * for building the function in the proxy class.
	  // */
		// var getFirstParameterOfType = function (type :Type) :ComplexType {
		// 	switch(type) {
		// 		case TInst(classTypeRef, params):
		// 			if (params != null && params.length > 0) {
		// 				var firstParam = params[0];
		// 				return convertTypeParamToTypePathParam(firstParam);
		// 			}
		// 		default: Context.error("Getting the parameter of a non-TInst is currently not implemented", Context.currentPos());
		// 	}
		// 	return null;
		// }
			
		
		// var convertNodeRelayToCallback = function (f :{t: Type, opt: Bool, name: String}) :haxe.macro.FunctionArg {
		// 	return {
		// 		value: null, //No default args yet
		// 		type: convertTypeParamToTypePathParam(f.t),
		// 		opt: false,
		// 		name: "cb"
		// 	};
		// }
		
		
		
		// var createFunctionArgFromExistingFunctionArg = function (f :{t: Type, opt: Bool, name: String}) :haxe.macro.FunctionArg {
		// 	var argType = switch (f.t) {
		// 		case TInst(t, params): 
		// 			ComplexType.TPath({
		// 				sub: null,
		// 				params: [],//Ignore type parameters for now
		// 				pack: t.get().pack,
		// 				name: t.get().name
		// 			});
		// 		case TFun(args, ret):
		// 		case TEnum(t, params):
		// 			ComplexType.TPath({
		// 				sub: null,
		// 				params: [],//Ignore type parameters for now
		// 				pack: t.get().pack,
		// 				name: t.get().name
		// 			});
		// 		// case TType(t, params):
		// 		// case TMono(t):
		// 		// case TDynamic(t):
		// 		// case TAnonymous(a): 
		// 		default: null;
		// 	}
			
		// 	return {
		// 		value: null, //No default args yet
		// 		type: argType,
		// 		opt: f.opt,
		// 		name: f.name
		// 	} 
		// }
		
		
		
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
		// managerClass.
		switch (managerClass) {
			case TInst(classType, params):
				//Exclude the manager class from compilation into the client.  Very important.
				// classType.get().exclude();
				
				//Search for fields with @remote metadata, and add them to the proxy
				//typedef haxe.macro.ClassField
				for (f in classType.get().fields.get()) {
					var field :haxe.macro.ClassField = f;
					//Ignore non-remote methods
					if (!field.meta.has("remote")) {
						continue;
					}
					
					// Context.warning("      field.name=" + field.name, pos);
					var args = null;//:Array<{t: Type, opt: Bool, name: String}>
					var returnType :Type = null;
					//Ignore non-method fields
					// warn(field);
					// warn(StdType.enumConstructor(field.type));
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
						expr: {expr: ExprDef.EBlock([]), pos:pos},//{expr: createRemotingFunctionBlock(remotingId, args, pos), pos :pos},
						args: []
					}
					
					//arg of type { t : Type, opt : Bool, name : String }
					//Add the args, except the last, which is the NodeRelay argument
					// if (args != null && args.length > 1) {
					// 	for (arg in args.slice(0, args.length - 1)) {
					// 		func.args.push(createFunctionArgFromExistingFunctionArg(arg));
					// 	}
					// }
					
					// if (args != null && args.length > 0) {
					// 	func.args.push(convertNodeRelayToCallback(args[args.length - 1]));
					// }
					
					//Convert the NodeRelay arg to 
					
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
	
	
	// static function createFunctionArgFromExistingFunctionArg (f :{t: Type, opt: Bool, name: String}) :haxe.macro.FunctionArg
	// {
	// 	var argType = switch (f.t) {
	// 		case TInst(t, params): 
	// 			ComplexType.TPath({
	// 				sub: null,
	// 				params: [],//Ignore type parameters for now
	// 				pack: t.get().pack,
	// 				name: t.get().name
	// 			});
	// 		case TFun(args, ret):
	// 		case TEnum(t, params):
	// 			ComplexType.TPath({
	// 				sub: null,
	// 				params: [],//Ignore type parameters for now
	// 				pack: t.get().pack,
	// 				name: t.get().name
	// 			});
	// 		// case TType(t, params):
	// 		// case TMono(t):
	// 		// case TDynamic(t):
	// 		// case TAnonymous(a): 
	// 		default: null;
	// 	}
		
	// 	return {
	// 		value: null, //No default args yet
	// 		type: argType,
	// 		opt: f.opt,
	// 		name: f.name
	// 	} 
	// }
	
	//haxe.macro.Function.param
	// static function convertNodeRelayToCallback (f :{t: Type, opt: Bool, name: String}) :haxe.macro.FunctionArg
	// {
	// 	return {
	// 		value: null, //No default args yet
	// 		type: convertTypeParamToTypePathParam(f.t),
	// 		opt: false,
	// 		name: "cb"
	// 	};
	// }
	

	
	// static function createRemotingFunctionBlock (remotingId :String, 
	// 	functionArgs :Array<{ t : Type, opt : Bool, name : String }>, pos :haxe.macro.Position) :ExprDef 
	// {
	// 	// Create the function block
	// 	//Function args less the callback
	// 	var functionArgsForBlock = new Array<String>();
	// 	var callBackName :String = null;
	// 	if (functionArgs != null) {
	// 		for (arg in functionArgs) {
	// 			switch(arg.t) {
	// 				case TFun(args, ret)://Ignore the callbacks
	// 					callBackName = arg.name;
	// 				default: //add the rest
	// 					functionArgsForBlock.push(arg.name);
	// 			}
	// 		}
	// 	}
		
	// 	//Create the function block via parsing a string (too complicated otherwise)
	// 	var exprStr = '_conn.resolve("' + remotingId + '").call([' + 
	// 		functionArgsForBlock.join(", ") + ']' + (callBackName != null ? ', ' + callBackName: "") + ')';
	// 	return ExprDef.EBlock([
	// 		haxe.macro.Context.parse(exprStr, pos)
	// 	]);
	// }
	
	
	
	
	

	
	
	
	/**
	  * Helper functions
	  */
	#if macro
	/**
	  * Adds all methods from implemented interfaces for a class extending 
	  * net.amago.components.remoting.AsyncProxy
	  */
	static function createAsyncProxyMethodsFromInterfaceInternal(interfaceName :String) :Array<Field>
	{
		// var classType = null;
		// switch(type) {
		// 	case TInst(t, params):
		// 		classType = t.get();
		// 	default: 
		// 		Context.warning("Cannot create proxy methods from type=" + type, Context.currentPos());
		// 		return [];
		// }
		
		var fields = [];
		var pos = Context.currentPos();
		
		var functionRegex : EReg = ~/^[ \t]*function[ \t]*.*/;
		var interfaceFunctionExprs = [];
		
		// for (d in classType.interfaces) {
			// var interfaceName = d.t.get().pack.join("/") + "/" + d.t.get().name + ".hx";
			var interfaceFileName = interfaceName.split(".").join("/") + ".hx";
			var path = Context.resolvePath(interfaceFileName);
			for (line in neko.io.File.getContent(path).split("\n")) {
				if (functionRegex.match(line)) {
					var parserCompatibleLine = line.replace("Void;", "Void {}");
					var functionExpr = Context.parse(parserCompatibleLine, pos);
					switch(functionExpr.expr) {
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
							
						default: haxe.macro.Context.warning("Should not be here", pos);
					}
				}
			}
		// }
		return fields;
	}
	
	
	public static function createAsyncProxyMethodsFromRemoteClassInternal(remoteClassName : String, 
		?replaceLastArgWithNodeRelay :Bool = true) :Array<Field>
	{
		var pos = Context.currentPos();
		var fields = [];
		
		var remotingId = MacroUtil.getRemotingIdFromClassDef(remoteClassName);
		
		//Add the constructor
		fields.push(MacroUtil.createNewFunctionBlock(remotingId, pos));
		
		// Add "var _conn :haxe.remoting.AsyncConnection;"
		fields.push(MacroUtil.createConnectionField(pos));
		
		var remoteMetaRegex : EReg = ~/^[ \t]@remote.*/;
		var functionRegex : EReg = ~/^.*function.*/;
		// var functionRegex : EReg = ~/^[ \t]*(@remote[\t ]+)?(public[\t ]+)?functio[n][ \t]+.*/;
		//:[\t ]*Void[\t ]*$
		var interfaceFunctionExprs = [];
		
		// Context.warning("path=" + Context.resolvePath(remoteClassName), pos);
		
		var path = Context.resolvePath(remoteClassName.split(".").join("/") + ".hx");
		
		var lines = neko.io.File.getContent(path).split("\n");
		for (ii in 0...lines.length) {
			
			if (lines[ii].indexOf("function") > -1) {
				if (!functionRegex.match(lines[ii])) {
					Context.warning("Function doesn't match=" + lines[ii], pos);
				}
			}
			
			if (functionRegex.match(lines[ii])) {
				if (ii > 0 && (remoteMetaRegex.match(lines[ii - 1]) || lines[ii].indexOf("@remote") > -1)) {
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
							
							if (replaceLastArgWithNodeRelay) {
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
									default: Context.error("Last function arg must be a NodeRelay<Foo>", pos);
								}
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
	
	/**
	  * For getting a NodeRelay<SomeType> and getting the SomeType as a ComplexType 
	  * for building the function in the proxy class.
	  */
	// static function getFirstParameterOfType (type :Type) :ComplexType 
	// {
	// 	switch(type) {
	// 		case TInst(classTypeRef, params):
	// 			if (params != null && params.length > 0) {
	// 				var firstParam = params[0];
	// 				return convertTypeParamToTypePathParam(firstParam);
	// 			}
	// 		default: Context.error("Getting the parameter of a non-TInst is currently not implemented", Context.currentPos());
	// 	}
	// 	return null;
	// }
	
	// public static function convertTypeParamToTypePathParam (typeParam : Type) :ComplexType
	// {
	// 	switch(typeParam) {
	// 		case TInst(classType, params):
	// 			return ComplexType.TPath(
	// 				{
	// 					sub: null,
	// 					//Array<TypeParam>
	// 					params: classType.get().params.map(function (paramData :{t: Type, name: String}) :TypeParam {
	// 						return TypeParam.TPType(convertTypeParamToTypePathParam(paramData.t));
	// 					}).filter(function (val :Dynamic) :Bool {return val != null;}).array(),
	// 					pack: classType.get().pack,
	// 					name: classType.get().name
	// 				});
	// 		default:
	// 			Context.error("Type param conversion not yet implemented=" + typeParam, Context.currentPos());
	// 	}
	// 	return null;
	// }
	
	#end
	
	
	
}
