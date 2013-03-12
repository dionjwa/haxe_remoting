/*******************************************************************************
 * Hydrax: haXe port of the PushButton Engine
 * Copyright (C) 2010 Dion Amago
 * For more information see http://github.com/dionjwa/Hydrax
 *
 * This file is licensed under the terms of the MIT license, which is included
 * in the License.html file at the root directory of this SDK.
 ******************************************************************************/
package transition9.websockets;

#if haxe3
import Type in StdType;
#else
typedef StdType = Type;
#end

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
	 * Websocket build macro
	  * Adds custom serialization functions 
	  * http://haxe.org/manual/serialization
	  * for all fields with the annotation @serialize
	  */
	#if haxe3
	macro
	#else
	@:macro
	#end
	public static function buildWebsocketMessage() :Array<Field>
	{
		if (Context.defined("display")) {
			// When running in code completion, skip out early
			return haxe.macro.Context.getBuildFields();
		}
		
		var pos = Context.currentPos();
		
		var cls = Context.getLocalClass().get();
		
		//add 'keep' metadata to tell the compiler to not remove methods with --dead-code-elimination
		//which will remove the hxSerialize methods, for instance.
		cls.meta.add(":keep", [], pos);
		
		// Context.warning("cls: " + cls, pos);
		
		var serializableFieldNames = [];
		var classfields :Array<ClassField> = MacroUtil.getAllClassFields(cls);
		
		if (classfields != null) {
			for (classField in classfields) {
				if (classField.meta.has("serialize")) {
					serializableFieldNames.push(classField.name);
					if (!classField.meta.has(":keep")) {
						classField.meta.add(":keep", [], pos);
					}
				}
			}
		}
		
		var buildFields = haxe.macro.Context.getBuildFields();
		
		for (f in buildFields) {
			if (f.meta != null) {
				for (m in f.meta) {
					if (m.name == "serialize") {
						serializableFieldNames.push(f.name);
						break;
					}
				}
			}
		}
		
		var serializeExpressions = [];
		var unserializeExpressions = [];
		for (field in serializableFieldNames) {
			serializeExpressions.push(Context.parse("s.serialize(" + field + ")", pos));
			#if debug
			unserializeExpressions.push(Context.parse('trace("unserializing ' + field + '")', pos));
			#end
			unserializeExpressions.push(Context.parse(field + " = s.unserialize()", pos));
		}
		
		var serializeBlock = {expr:ExprDef.EBlock(serializeExpressions), pos :pos};
		var unserializeBlock = {expr:ExprDef.EBlock(unserializeExpressions), pos :pos};
		
		var serializerFields = flambe.util.Macros.buildFields(macro {
			function public__hxSerialize(s: haxe.Serializer) {$serializeBlock;}
			function public__hxUnserialize(s: haxe.Unserializer) {$unserializeBlock;}
		});
		
		for (newField in serializerFields) {
			newField.meta = [{name:":keep", params:[], pos:pos}];
		}
		
		return haxe.macro.Context.getBuildFields().concat(serializerFields);
	}
}
