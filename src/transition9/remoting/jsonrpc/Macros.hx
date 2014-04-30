/*******************************************************************************
 * Hydrax: haXe port of the PushButton Engine
 * Copyright (C) 2010 Dion Amago
 * For more information see http://github.com/dionjwa/Hydrax
 *
 * This file is licensed under the terms of the MIT license, which is included
 * in the License.html file at the root directory of this SDK.
 ******************************************************************************/
package transition9.remoting.jsonrpc;

import Type in StdType;

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
	  * Takes a server remoting class and the connection variable,
	  * and returns an instance of the newly created proxy class.
	  */
	macro
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
				case TInst(typeRef, _):
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
			return buildRemoteProxyClassInternal(className, connectionExpr, implementExpr);
		}
	}

	/**
	  * Helper functions
	  */
	#if macro
	static function createAsyncProxyMethodsFromClassFile(
		remoteClassName : String,
		?asInterface :Bool = false) :Array<Field>
	{
		var pos = Context.currentPos();

		var fields = [];

		//Add the constructor
		if (!asInterface) {
			fields.push(createNewFunctionBlock(pos));
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

		if (!sys.FileSystem.exists(path)) {
			Context.error("Remoting class '" + remoteClassName + "' does not resolve to a valid path=" + path, pos);
		}

		var fileContent = "";
		// open and read file line by line
		var fin = sys.io.File.read(path, false);
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
			if (commentRegex.match(lines[ii])) {
				continue;
			}

			if (functionRegex.match(lines[ii])) {
				if (ii > 0 && (isInterface || ((remoteMetaRegex.match(lines[ii - 1]) || lines[ii].indexOf("@remote") > -1)))) {
					var parserCompatibleLine = lines[ii].replace("@remote", "").replace("public", "") + " :Int {}";
					parserCompatibleLine = parserCompatibleLine.trim().replace(";", "");
					var functionExpr = Context.parse(parserCompatibleLine, pos);

					switch(functionExpr.expr) {
						default://Do nothing
						case EFunction(name, f)://f is a Function
							//Function args less the callback
							var functionArgsForBlock = new Array<String>();
							var callBackName :String = "cb";

							//Check that the first callback arg is typed as a ResponseError
							if (f.args.length  > 0) {
								switch (f.args[f.args.length - 1].type) {
									case TFunction(args, ret):
										var firstArgType :ComplexType = args[0];
										switch(firstArgType) {
											case TPath(typePath):
												if (typePath.name != "RPC" || typePath.sub != "ResponseError") {
													Context.error(remoteClassName + "." + name + " does not have transition9.remoting.jsonrpc.RPC.ResponseError as the first callback argument " + firstArgType, pos);
												}
											default:Context.error(remoteClassName + "." + name + ": the first argument of the callback is not typed as a transition9.remoting.jsonrpc.RPC.ResponseError: " + firstArgType, pos);
										}

									default: Context.warning(remoteClassName + "." + name + " does not have a callback", pos);
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
								var exprStr = 'return call("$remoteClassName.$name", ['
									+ functionArgsForBlock.join(", ") + '], cb)';
								var functionBlock = ExprDef.EBlock([
									haxe.macro.Context.parse(exprStr, pos)
								]);
								Reflect.setField(f, "expr", {expr:functionBlock, pos :pos});
							} else {
								Reflect.setField(f, "expr", null);
							}

							// var arg_count = f.args.length;
							var field : Field = {
								name : name,
								doc : null,
								access : asInterface ? [] : [Access.APublic],
								kind : FieldType.FFun(f),
								pos : pos,
								meta : [{name:"argument_count", params:[macro $v{f.args.length}], pos:pos}]
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
		var proxyClassName = getProxyRemoteClassName(className);

		var implement :Array<TypePath> = null;
		if (implementExpr != null) {
			implement = [];
			switch(Context.typeof(implementExpr)) {
				case TType(t, _):
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
		var superClassTypePath :TypePath = {params:[], pack:["transition9", "remoting", "jsonrpc"], name:"RPCProxy"};

		var newProxyType :haxe.macro.TypeDefinition = {
			pack: proxyClassName.split(".").length > 0 ? proxyClassName.split(".").slice(0, proxyClassName.split(".").length - 1) : [],
			name: proxyClassName.split(".")[proxyClassName.split(".").length - 1],
			pos: pos,
			meta: [],
			params: [],
			isExtern: false,
			kind: haxe.macro.TypeDefKind.TDClass(superClassTypePath, implement, false),
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

	/**
	 * Creates new block for a remoting proxy. Uses RPCConnection as the argument
	 */
	static function createNewFunctionBlock (pos :haxe.macro.Position) :Field
	{
		var exprStr = 'super(c)';

		var func :haxe.macro.Function = {
			ret: null,
			params: [],
			//The expression contains the call to the context
			expr: {expr: ExprDef.EBlock([haxe.macro.Context.parse(exprStr, pos)]), pos:pos},
			args: [{value:null, opt:false, name:"c", type:RPC_CONNECTION_TYPE}] //<FunctionArg>
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

	public static function getClassNameFromClassExpr (classNameExpr :Expr) :String
	{
		var drillIntoEField = null;
		var className = "";
		drillIntoEField = function (e :Expr) :String {
			switch(e.expr) {
				case EField(e2, field):
					return drillIntoEField(e2) + "." + field;
				case EConst(c):
					switch(c) {
						case CIdent(s):
							return s;
						case CString(s):
							return s;
						default:Context.warning(StdType.enumConstructor(c) + " not handled", Context.currentPos());
							return "";
					}
				default: Context.warning(StdType.enumConstructor(e.expr) + " not handled", Context.currentPos());
					return "";
			}
		}
		switch(classNameExpr.expr) {
			case EField(e1, field):
				className = field;
				switch(e1.expr) {
					case EField(_, _):
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
						className = s;
					case CString(s):
						className = s;
					default:Context.warning(StdType.enumConstructor(c) + " not handled", Context.currentPos());
				}
			default: Context.warning(StdType.enumConstructor(classNameExpr.expr) + " not handled", Context.currentPos());
		}

		return className;
	}

	public static function buildService() :Array<Field>
	{
		var pos = Context.currentPos();
		var fields = haxe.macro.Context.getBuildFields();
		for (field in fields) {
			switch(field.kind) {
				case FFun(f):
					if (field.meta.length == 0) {
						continue;
					}
					var isRemoting = false;
					for (metaDataEntry in field.meta) {
						if (metaDataEntry.name == "remote") {
							isRemoting = true;
							break;
						}
					}
					if (!isRemoting) {
						continue;
					}
					field.meta.push({name:"arguments", params:[macro $v{f.args.length}], pos:pos});
				default://Ignore the others
			}
		}
		return fields;
	}

	public static function getProxyRemoteClassName(className : String) :String
	{
		return className + "Proxy";
	}
	#end

	#if macro
	static var RPC_CONNECTION_TYPE : ComplexType = ComplexType.TPath({sub:null, params:[], pack:["transition9", "remoting", "jsonrpc"], name:"ConnectionClient"});
	#end
}
