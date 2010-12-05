/* jscodegen.vala
 *
 * Copyright (C) 2010  Luca Bruno
 * Copyright (C) 2006-2010  Jürg Billeter
 * Copyright (C) 2006-2008  Raffaele Sandrini
 *
 * This file is part of Maja, derived from valaccodebasemodule.vala of Vala.
 *
 * Maja is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 3 of
 * the License, or (at your option) any later version.
 *
 * Maja is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with Maja. If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 * 	Luca Bruno <lethalman88@gmail.com>
 */

using Vala;

/**
 * Code visitor generating C Code.
 */
public class Maja.JSCodeGenerator : CodeGenerator {
	public enum ControlFlowStatement {
		RETURN,
		BREAK,
		CONTINUE
	}

	public class EmitContext {
		public Symbol? current_symbol;
		public Gee.LinkedList<Symbol> symbol_stack = new Gee.LinkedList<Symbol> ();
		public TryStatement current_try;
		public JSBlockBuilder js;
		public Gee.LinkedList<JSBlockBuilder> js_stack = new Gee.LinkedList<JSBlockBuilder> ();
		public int next_temp_var_id;
		public Gee.Map<string,string> variable_name_map = new Gee.HashMap<string,string> (str_hash, str_equal);

		public EmitContext (Symbol? symbol = null) {
			current_symbol = symbol;
		}

		public void push_symbol (Symbol symbol) {
			symbol_stack.offer_head (current_symbol);
			current_symbol = symbol;
		}

		public void pop_symbol () {
			current_symbol = symbol_stack.poll_head ();
		}
	}

	public CodeContext context { get; set; }

	public Symbol root_symbol;

	public EmitContext emit_context = new EmitContext ();

	Gee.List<EmitContext> emit_context_stack = new Gee.ArrayList<EmitContext> ();

	public Symbol current_symbol { get { return emit_context.current_symbol; } }

	public TryStatement current_try {
		get { return emit_context.current_try; }
		set { emit_context.current_try = value; }
	}

	public TypeSymbol? current_type_symbol {
		get {
			var sym = current_symbol;
			while (sym != null) {
				if (sym is TypeSymbol) {
					return (TypeSymbol) sym;
				}
				sym = sym.parent_symbol;
			}
			return null;
		}
	}

	public Class? current_class {
		get { return current_type_symbol as Class; }
	}

	public Method? current_method {
		get {
			var sym = current_symbol;
			while (sym is Block) {
				sym = sym.parent_symbol;
			}
			return sym as Method;
		}
	}

	public PropertyAccessor? current_property_accessor {
		get {
			var sym = current_symbol;
			while (sym is Block) {
				sym = sym.parent_symbol;
			}
			return sym as PropertyAccessor;
		}
	}

	public DataType? current_return_type {
		get {
			var m = current_method;
			if (m != null) {
				return m.return_type;
			}

			var acc = current_property_accessor;
			if (acc != null) {
				if (acc.readable) {
					return acc.value_type;
				} else {
					return void_type;
				}
			}

			if (is_in_constructor () || is_in_destructor ()) {
				return void_type;
			}

			return null;
		}
	}

	bool is_in_constructor () {
		var sym = current_symbol;
		while (sym != null) {
			if (sym is Constructor) {
				return true;
			}
			sym = sym.parent_symbol;
		}
		return false;
	}

	bool is_in_destructor () {
		var sym = current_symbol;
		while (sym != null) {
			if (sym is Destructor) {
				return true;
			}
			sym = sym.parent_symbol;
		}
		return false;
	}

	bool is_in_loop (bool captured) {
		var captured_block = current_closure_block;
		var sym = current_symbol;
		while (sym != null) {
			if (!(sym is Block) || (captured && sym == captured_block)) {
				break;
			}
			if (sym.parent_node is Loop) {
				return true;
			}
			sym = sym.parent_symbol;
		}
		return false;
	}

	bool is_simple_field (Symbol sym) {
		if (sym.get_full_name () in simple_fields) {
			return true;
		}
		return sym.get_attribute ("SimpleField") != null;
	}

	public Block? current_closure_block {
		get {
			return next_closure_block (current_symbol);
		}
	}

	public unowned Block? next_closure_block (Symbol sym) {
		unowned Block block = null;
		while (true) {
			block = sym as Block;
			if (!(sym is Block)) {
				// no closure block
				break;
			}
			if (block != null && block.captured) {
				// closure block found
				break;
			}
			sym = sym.parent_symbol;
		}
		return block;
	}

	public EmitContext namespace_decl_context;
	public EmitContext decl_context;
	public EmitContext base_init_context;

	public JSBlockBuilder js { get { return emit_context.js; } }

	/* contains all the declared symbols */
	Set<Symbol> declared_symbols = new HashSet<Symbol> ();
	/* (constant) hash table with all reserved identifiers in the generated code */
	Set<string> reserved_identifiers = new HashSet<string> (str_hash, str_equal);
	/* (constant) set with full name of simple fields */
	Set<string> simple_fields = new HashSet<string> (str_hash, str_equal);
	/* (constant) set with full name of dova -> javascript mappings */
	Map<string,string> static_method_mapping = new HashMap<string,string> (str_hash, str_equal);
	/* (constant) set with full name of native javascript mappings */
	Map<string,string> native_mapping = new HashMap<string,string> (str_hash, str_equal);

	public Gee.Map<string,string> variable_name_map {
		get { return emit_context.variable_name_map; }
	}

	public int next_temp_var_id {
		get { return emit_context.next_temp_var_id; }
		set { emit_context.next_temp_var_id = value; }
	}

	public DataType void_type = new VoidType ();
	public DataType bool_type;
	public DataType char_type;
	public DataType int_type;
	public DataType uint_type;
	public DataType double_type;
	public DataType string_type;
	public DataType object_type;

	public JSCodeGenerator () {
        // TODO:
		reserved_identifiers.add ("this");
		reserved_identifiers.add ("for");
		reserved_identifiers.add ("while");

		// reserved for Maja naming conventions
		reserved_identifiers.add ("error");

		simple_fields.add ("Dova.List.length");

		static_method_mapping["string.contains"] = "string.prototype.contains";

		native_mapping["string.index_of"] = "indexOf";
		native_mapping["string.to_string"] = "toString";
		native_mapping["int.to_string"] = "toString";
	}

	public override void emit (CodeContext context) {
		this.context = context;

		root_symbol = context.root;

		var jsfile = new JSFile ();

		namespace_decl_context = new EmitContext ();
		push_context (namespace_decl_context);
		var jsblock = new JSBlock ();
		jsblock.no_semicolon = true;
		jsfile.statements.add (jsblock);
		push_function (new JSBlockBuilder (jsblock));
		pop_context ();

		decl_context = emit_context;
		jsblock = new JSBlock ();
		jsblock.no_semicolon = true;
		jsfile.statements.add (jsblock);
		push_function (new JSBlockBuilder (jsblock));

		context.root.accept_children (this);

		if (context.entry_point != null) {
			jsfile.statements.add (jsmember (context.entry_point.get_full_name ()).call ());
		}

		var jssource_filename = "%s.js".printf (context.output);
		if (!jsfile.store (jssource_filename, null, context.version_header, context.debug)) {
			Report.error (null, "unable to open `%s' for writing".printf (jssource_filename));
		}
	}

	public void push_context (EmitContext emit_context) {
		if (this.emit_context != null) {
			emit_context_stack.add (this.emit_context);
		}

		this.emit_context = emit_context;
	}

	public void pop_context () {
		if (emit_context_stack.size > 0) {
			this.emit_context = emit_context_stack[emit_context_stack.size - 1];
			emit_context_stack.remove_at (emit_context_stack.size - 1);
		} else {
			this.emit_context = null;
		}
	}

	public void push_function (JSBlockBuilder builder) {
		emit_context.js_stack.offer_head (builder);
		emit_context.js = builder;
	}

	public void pop_function () {
		emit_context.js_stack.poll_head ();
		emit_context.js = emit_context.js_stack.peek_head ();
	}

	public bool add_symbol_declaration (Symbol sym) {
		if (sym in declared_symbols) {
			return true;
		}
		declared_symbols.add (sym);

		if (sym.source_reference != null) {
			sym.source_reference.file.used = true;
		}
		if (sym.external_package) {
			// declaration complete
			return true;
		} else {
			// require declaration
			return false;
		}
	}

	public override void visit_namespace (Namespace ns) {
		if (ns.external_package) {
			return;
		}

		push_context (namespace_decl_context);
		js.stmt (jsmember(ns.get_full_name ()).assign (jsobject ()));
		pop_context ();

		ns.accept_children (this);
	}

	public override void visit_class (Class cl) {
		if (add_symbol_declaration (cl)) {
			return;
		}

		if (cl.base_class != null) {
			cl.base_class.accept (this);
		}

		push_context (new EmitContext (cl));

		// constructor defines the class too
		generate_construction_method (cl, cl.default_construction_method as CreationMethod);
		if (cl.base_class != null) {
			push_context (decl_context);
			js.stmt (jsmaja().member("inherit").call (jslist().add (jsmember(cl.get_full_name())).add (jsmember(cl.base_class.get_full_name()))));
			pop_context ();
		}

		// init function
		base_init_context = new EmitContext (cl);
		push_context (base_init_context);
		var init_func = jsfunction ();
		push_function (init_func);
		if (cl.base_class != null) {
			js.stmt (jsmember(cl.base_class.get_full_name()).member("prototype._maja_init").member("call").call(jsmember("this")));
		}
		pop_context ();

		push_context (decl_context);
		js.stmt (jsmember(cl.get_full_name()).member("prototype._maja_init").assign (init_func));
		pop_context ();

		cl.accept_children (this);
		pop_context ();
	}

	public override void visit_method (Method m) {
		if (m.external) {
			return;
		}

		var func = generate_method (m);

		// declare function
		var def = jsexpr ();
		if (current_type_symbol != null) {
			def.member (current_type_symbol.get_full_name ());
			if (m.binding == MemberBinding.INSTANCE) {
				def.member ("prototype");
			}
		}
		def.member (m.name).assign (func);
		push_context (decl_context);
		js.stmt (def);
		pop_context ();
	}

	public override void visit_creation_method (CreationMethod m) {
		if (m.external) {
			return;
		}

		push_context (new EmitContext (m));

		var cl = current_class;
		if (!(cl == null || m == cl.default_construction_method)) {
			generate_construction_method (cl, m);
		}

		pop_context ();
	}

	public override void visit_formal_parameter (Vala.Parameter param) {
		if (param.ellipsis) {
			return;
		}

		if (param.direction == ParameterDirection.IN) {
			/* NON-SPECIAL SANITY CHECKS
			  var param_list = (JSList) js.current.expr;
			param_list.add_string (param.name);

			if (!param.variable_type.nullable) {
				js.open_if (jsmember (param.name).equal (jsnull ()));
				js.error (jsstring ("Unexpected null parameter '"+param.name+"'"));
				js.close ();
				}*/

			var param_list = (JSList) js.current.expr;
			param_list.add_string ("param_"+param.name);
			// initialize default
			// declare local variable for parameter
			js.stmt (jsvar(param.name));
			js.open_if (jsmember("param_"+param.name).inequal (jsundefined ()));
			if (!param.variable_type.nullable) {
				js.open_if (jsmember("param_"+param.name).equal (jsnull ()));
				js.error (jsstring ("Unexpected null parameter '"+param.name+"'"));
				js.close ();
			}
			js.stmt (jsmember(param.name).assign (jsmember("param_"+param.name)));
			js.add_else ();
			if (param.initializer != null) {
				param.initializer.emit (this);
				js.stmt (jsmember(param.name).assign (get_jsvalue (param.initializer)));
			} else {
				js.error (jsstring ("Undefined parameter '"+param.name+"'"));
			}
			js.close ();
		} else {
			JSCode rhs = null;
			if (param.initializer != null) {
				param.initializer.emit (this);
				rhs = get_jsvalue (param.initializer);
			} else {
				rhs = jsnull ();
			}
			js.stmt (jsvar(param.name).assign (rhs));
		}
	}

	public override void visit_block (Block block) {
		JSBlockBuilder func = null;
		if (block.captured) {
			func = jsfunction ();
			push_function (func);
		}
		emit_context.push_symbol (block);
		foreach (var stmt in block.get_statements ()) {
			stmt.emit (this);
		}
		if (block.captured) {
			pop_function ();
			var temp = get_temp_variable_name ();
			js.stmt (jsvar (temp).assign (jsexpr (func).parens ().call ()));
			// we are temporarly out of the captured block
			block.captured = false;
			js.open_if (jsmember (temp).equal (jsinteger (ControlFlowStatement.RETURN)));
			emit_control_flow_statement (ControlFlowStatement.RETURN);
			if (is_in_loop (false)) {
				js.add_else_if (jsmember (temp).equal (jsinteger (ControlFlowStatement.BREAK)));
				emit_control_flow_statement (ControlFlowStatement.BREAK);
				js.add_else_if (jsmember (temp).equal (jsinteger (ControlFlowStatement.CONTINUE)));
				emit_control_flow_statement (ControlFlowStatement.CONTINUE);
			}
			js.close ();
			block.captured = true;
		}
		emit_context.pop_symbol ();
	}

	public override void visit_declaration_statement (DeclarationStatement stmt) {
		stmt.declaration.accept (this);
	}

	public override void visit_local_variable (LocalVariable local) {
		var decl = jsvar (get_variable_jsname (local.name));
		if (local.initializer != null) {
			local.initializer.emit (this);
			decl.assign (get_jsvalue (local.initializer));
		}
		js.stmt (decl);
	}

	public override void visit_binary_expression (BinaryExpression expr) {
		expr.left.emit (this);
		expr.right.emit (this);
		var jsleft = get_jsvalue (expr.left);
		var jsright = get_jsvalue (expr.right);

		var jscode = jsexpr (jsleft);
		switch (expr.operator) {
		case BinaryOperator.PLUS:
			jscode.plus (jsright);
			break;
		case BinaryOperator.MINUS:
			jscode.minus (jsright);
			break;
		case BinaryOperator.LESS_THAN:
			jscode.lt (jsright);
			break;
		case BinaryOperator.GREATER_THAN:
			jscode.gt (jsright);
			break;
		case BinaryOperator.LESS_THAN_OR_EQUAL:
			jscode.le (jsright);
			break;
		case BinaryOperator.GREATER_THAN_OR_EQUAL:
			jscode.ge (jsright);
			break;
		case BinaryOperator.EQUALITY:
			jscode.equal (jsright);
			break;
		case BinaryOperator.INEQUALITY:
			jscode.inequal (jsright);
			break;
		case BinaryOperator.AND:
			jscode.and (jsright);
			break;
		case BinaryOperator.OR:
			jscode.or (jsright);
			break;
		default:
			assert_not_reached ();
		}

		set_jsvalue (expr, jscode);
	}

	public override void visit_unary_expression (UnaryExpression expr) {
		switch (expr.operator) {
		case UnaryOperator.OUT:
		case UnaryOperator.REF:
		case UnaryOperator.PLUS:
			set_jsvalue (expr, get_jsvalue (expr.inner));
			break;
		case UnaryOperator.LOGICAL_NEGATION:
			set_jsvalue (expr, jsexpr (get_jsvalue (expr.inner)).negate ());
			break;
		case UnaryOperator.MINUS:
			set_jsvalue (expr, jsexpr (get_jsvalue (expr.inner)).minus ());
			break;
		default:
			assert_not_reached ();
		}
	}

	public override void visit_null_literal (NullLiteral expr) {
		set_jsvalue (expr, jsnull ());
	}

	public override void visit_integer_literal (IntegerLiteral expr) {
		set_jsvalue (expr, jstext (expr.value + expr.type_suffix));
	}

	public override void visit_boolean_literal (BooleanLiteral expr) {
		set_jsvalue (expr, jstext (expr.value ? "true" : "false"));
	}

	public override void visit_string_literal (StringLiteral expr) {
		set_jsvalue (expr, jstext (expr.value.replace("\n", "\\n")));
	}

	public override void visit_return_statement (ReturnStatement stmt) {
		var m = current_method;
		JSExpressionBuilder result = null;
		if (!(current_return_type is VoidType)) {
			result = jsmember("result");
		}

		bool has_out_parameters = false;
		if (m != null) {
			foreach (var param in m.get_parameters ()) {
				if (param.direction == ParameterDirection.IN)
					continue;
				if (!has_out_parameters) {
					has_out_parameters = true;
					if (result == null)
						result = jsexpr().array ();
					else
						result.array ();
				}
				result.add_array_element (jstext (param.name));
			}
		}

		if (result != null) {
			if (current_return_type is VoidType) {
				js.stmt (jsvar ("result").assign (result));
			} else if (has_out_parameters) {
				js.stmt (jsmember ("result").assign (result));
			}
			emit_control_flow_statement (ControlFlowStatement.RETURN);
		}
	}

	public override void visit_break_statement (BreakStatement stmt) {
		emit_control_flow_statement (ControlFlowStatement.BREAK);
	}

	public override void visit_continue_statement (ContinueStatement stmt) {
		emit_control_flow_statement (ControlFlowStatement.CONTINUE);
	}

	public override void visit_member_access (MemberAccess ma) {
		JSExpressionBuilder jscode = null;

		var member_name = ma.member_name;
		if (ma.member_name != "this") {
			member_name = get_variable_jsname (member_name);
		}
		if (ma.inner != null) {
			var static_method_name = static_method_mapping[ma.symbol_reference.get_full_name ()];
			if (static_method_name != null) {
				jscode = jsbind (jsmember (static_method_name), get_jsvalue (ma.inner));
			} else {
				var native_name = native_mapping[ma.symbol_reference.get_full_name ()];
				if (native_name != null) {
					member_name = native_name;
				}
				jscode = jsexpr (get_jsvalue (ma.inner));
				var prop = ma.symbol_reference as Property;
				if (prop != null && !is_simple_field (prop)) {
					jscode.member (get_symbol_jsname (prop, "get_"+member_name)).call ();
				} else {
					jscode.member (member_name);
				}
			}
		} else {
			jscode = jsmember (member_name);
		}

		set_jsvalue (ma, jscode);
	}

	public override void visit_field (Field field) {
		if (field.external) {
			return;
		}

		if (field.binding == MemberBinding.INSTANCE) {
			push_context (base_init_context);
			JSCode rhs = null;
			if (field.initializer != null) {
				field.initializer.emit (this);
				rhs = get_jsvalue (field.initializer);
			} else {
				rhs = jsnull ();
			}
			js.stmt (jsmember("this").member(field.name).assign (rhs));
			pop_context ();
		}
	}

	public override void visit_property (Property prop) {
		if (prop.external) {
			return;
		}

		prop.accept_children (this);
	}

	public override void visit_property_accessor (PropertyAccessor acc) {
		push_context (new EmitContext (acc));
		var func = jsfunction ();
		push_function (func);
		if (acc.writable && acc.value_parameter != null) {
			acc.value_parameter.accept (this);
		}
		acc.body.emit (this);
		pop_context ();

		var name = acc.parent_symbol.name;
		if (acc.readable) {
			name = "get_"+name;
		} else {
			name = "set_"+name;
		}
		push_context (decl_context);
		js.stmt (jsmember (acc.parent_symbol.parent_symbol.get_full_name ()).member ("prototype").member (name).assign (func));
		pop_context ();
	}

	public override void visit_expression_statement (ExpressionStatement stmt) {
		var jscode = get_jsvalue (stmt.expression);
		if (jscode != null)
			js.stmt (jscode);
	}

	public override void visit_object_creation_expression (ObjectCreationExpression expr) {
		var cl = expr.type_reference.data_type as Class;
		if (cl == null)
			return;
		var jscode = jsmember (cl.get_full_name ());
		if (expr.symbol_reference != cl.default_construction_method)
			jscode.member (expr.symbol_reference.name);
		jscode = emit_call (expr.symbol_reference as CreationMethod, jscode, expr.get_argument_list (), null, expr);
		set_jsvalue (expr, jscode.keyword ("new"));
	}

	public override void visit_assignment (Assignment expr) {
		expr.left.emit (this);
		expr.right.emit (this);
		var ma = expr.left as MemberAccess;
		if (ma != null) {
			var prop = ma.symbol_reference as Property;
			if (prop != null && !is_simple_field (prop)) {
				var set_expr = jsexpr(get_jsvalue (ma.inner)).member (get_symbol_jsname (prop, "set_"+prop.name));
				if (!(expr.parent_node is ExpressionStatement)) {
					var temp = get_temp_variable_name ();
					js.stmt (jsvar(temp).assign (get_jsvalue (expr.right)));
					js.stmt (jsexpr(get_jsvalue (ma.inner)).member (get_symbol_jsname (prop, "set_"+prop.name)).call (jsmember (temp)));
					set_jsvalue (expr, jsmember (temp));
				} else {
					set_jsvalue (expr, set_expr.call (get_jsvalue (expr.right)));
				}
				return;
			}
		}
		set_jsvalue (expr, jsexpr(get_jsvalue (expr.left)).assign (get_jsvalue (expr.right)));
	}

	public override void visit_method_call (MethodCall expr) {
		if (expr.call.symbol_reference.get_full_name () == "string.equals") {
			var arguments = expr.get_argument_list ();
			set_jsvalue (expr, jsexpr (get_jsvalue (arguments[0])).equal (get_jsvalue (arguments[1])));
			return;
		}

		CodeNode callable;
		if (expr.call.symbol_reference is Class) {
			callable = ((Class) expr.call.symbol_reference).default_construction_method;
		} else if (expr.call.value_type is DelegateType) {
			callable = ((DelegateType) expr.call.value_type).delegate_symbol;
		} else {
			callable = (Method) expr.call.symbol_reference;
		}

		bool has_out_parameters;
		var jscode = emit_call (callable, jsexpr (get_jsvalue (expr.call)), expr.get_argument_list (), out has_out_parameters, expr);
		if (!(expr.parent_node is ExpressionStatement && has_out_parameters)) {
			set_jsvalue (expr, jscode);
		}
	}

	public override void visit_base_access (BaseAccess expr) {
		set_jsvalue (expr, jsbind (jsmember (expr.symbol_reference.get_full_name())));
	}

	public override void visit_if_statement (IfStatement stmt) {
		js.open_if (get_jsvalue (stmt.condition));
		stmt.true_statement.emit (this);
		if (stmt.false_statement != null) {
			js.add_else ();
			stmt.false_statement.emit (this);
		}
		js.close ();
	}

	public override void visit_loop (Loop loop) {
		js.open_while (jstext("true"));
		loop.body.emit (this);
		js.close ();
	}

	public override void visit_postfix_expression (PostfixExpression expr) {
		var orig = get_jsvalue (expr.inner);
		var temp = get_temp_variable_name ();
		js.stmt (jsvar(temp).assign (orig));
		if (expr.increment)
			js.stmt (jsexpr(orig).increment ());
		else
			js.stmt (jsexpr(orig).decrement ());
		if (!(expr.parent_node is ExpressionStatement))
			set_jsvalue (expr, jsmember (temp));
	}

	public override void visit_lambda_expression (LambdaExpression expr) {
		set_jsvalue (expr, jsbind (generate_method (expr.method)));
	}

	public override void visit_list_literal (ListLiteral expr) {
		var jslist = jslist (true);
		foreach (var element in expr.get_expressions ())
			jslist.add (get_jsvalue (element));
		set_jsvalue (expr, jslist);
	}

	public override void visit_set_literal (SetLiteral expr) {
		var jsobj = jsobject ();
		foreach (var element in expr.get_expressions ())
			jsobj.add (get_jsvalue (element), jstext("true"));
		set_jsvalue (expr, jsobj);
	}

	public override void visit_map_literal (MapLiteral expr) {
		var jsobj = jsobject ();
		var key_it = expr.get_keys ().iterator ();
		var value_it = expr.get_values ().iterator ();
		while (key_it.next ()) {
			assert (value_it.next ());
			jsobj.add (get_jsvalue (key_it.get ()), get_jsvalue (value_it.get ()));
		}
		set_jsvalue (expr, jsobj);
	}

	public override void visit_throw_statement (ThrowStatement stmt) {
		js.stmt (jsexpr (get_jsvalue (stmt.error_expression)).keyword ("throw"));
	}

	public override void visit_try_statement (TryStatement stmt) {
		js.open_try ();
		stmt.body.emit (this);
		foreach (var clause in stmt.get_catch_clauses ()) {
			js.open_catch (clause.variable_name);
			clause.body.emit (this);
		}
		if (stmt.finally_body != null) {
			js.open_finally ();
			stmt.finally_body.emit (this);
		}
		js.close ();
	}

	public override void visit_array_creation_expression (ArrayCreationExpression expr) {
		var jssizes = jslist (true);
		foreach (var size in expr.get_sizes ()) {
			jssizes.add (get_jsvalue (size));
		}
		set_jsvalue (expr, jsmaja().member("array").call (jssizes));
	}

	public override void visit_element_access (ElementAccess expr) {
		var jsindices = jslist ();
		foreach (var index in expr.get_indices ()) {
			jsindices.add (get_jsvalue (index));
		}
		set_jsvalue (expr, jsexpr (get_jsvalue (expr.container)).element_code (jsindices));
	}

	public override void visit_cast_expression (CastExpression expr) {
		set_jsvalue (expr, get_jsvalue (expr.inner));
	}

	public JSCode generate_method (Method m) {
		push_context (new EmitContext (m));

		if (m.body != null) {
			bool return_found = false;
			// add default return if there's none
			foreach (var stmt in m.body.get_statements ()) {
				if (stmt is ReturnStatement) {
					return_found = true;
					break;
				}
			}
			if (!return_found) {
				m.body.add_statement (new ReturnStatement ());
			}
		}

		var func = jsfunction ();
		push_function (func);
		if (m.is_abstract) {
			js.error (jsstring ("Abstract method '%s' not implemented".printf (m.get_full_name ())));
		} else {
			m.accept_children (this);
		}

		pop_context ();

		return func;
	}

	public JSCode? get_jsvalue (Expression expr) {
		if (expr.target_value == null) {
			return null;
		}
		var js_value = (JSValue) expr.target_value;
		return js_value.jscode;
	}

	public void set_jsvalue (Expression expr, JSCode code) {
		expr.target_value = new JSValue (expr.target_type, code);
	}

	public JSBlockBuilder jsfunction (JSList parameters = new JSList ()) {
		return new JSBlockBuilder (new JSBlock (null, "function", parameters));
	}

	public JSExpressionBuilder jsexpr (JSCode? initial = null) {
		return new JSExpressionBuilder (initial);
	}

	public JSExpressionBuilder jstext (string text) {
		return jsexpr (new JSText (text));
	}

	public JSExpressionBuilder jsmember (string name) {
		return jstext (name);
	}

	public JSExpressionBuilder jsnull () {
		return jstext ("null");
	}

	public JSExpressionBuilder jsmaja () {
		return jstext ("Maja");
	}

	public JSExpressionBuilder jsundefined () {
		return jstext ("undefined");
	}

	public JSExpressionBuilder jsvar (string name) {
		var result = jsmember (name);
		result.keyword ("var");
		return result;
	}

	public JSList jslist (bool is_array = false) {
		return new JSList (is_array);
	}

	public JSObject jsobject () {
		return new JSObject ();
	}

	public JSExpressionBuilder jsbind (JSCode func, JSCode? scope = null) {
		return jsmaja().member("bind").call (jslist().add (scope ?? jsmember ("this")).add (func));
	}

	public JSExpressionBuilder jsinteger (int value) {
		return jstext ("%d".printf (value));
	}

	public JSExpressionBuilder jsstring (string value) {
		return jstext ("\"%s\"".printf (value));
	}

	public JSExpressionBuilder? emit_call (CodeNode callable, JSExpressionBuilder jscall, Vala.List<Expression> arguments, out bool has_out_results, CodeNode? node_reference = null) {
		var m = callable as Method;
		var d = callable as Delegate;
		bool has_result;
		if (m != null) {
			has_result = !(m.return_type is VoidType) || m is CreationMethod;
		} else {
			has_result = !(d.return_type is VoidType);
		}
		Expression[] out_results = null;
		has_out_results = false;
		var jsargs = jslist ();

		var arg_it = arguments.iterator ();
		Vala.List<Vala.Parameter> parameters;
		if (m != null) {
			parameters = m.get_parameters ();
		} else {
			parameters = d.get_parameters ();
		}
		foreach (var param in parameters) {
			if (!arg_it.next ())
				break;
			if (param.direction != ParameterDirection.IN) {
				var out_result = arg_it.get ();
				if (!has_out_results) {
					if (out_result.value_type is NullType)
						continue;
					out_results = new Expression[]{};
					has_out_results = true;
				}
				out_results += arg_it.get ();
			} else {
				jsargs.add (get_jsvalue (arg_it.get ()));
				if (param.variable_type is DelegateType) {
					var deleg = ((DelegateType) param.variable_type).delegate_symbol;
					var javascript = deleg.get_attribute ("Javascript");
					if (javascript != null && javascript.get_bool ("has_this_parameter")) {
						jsargs.add (jsnull ());
					}
				}
			}
		}

		jscall.call (jsargs);
		JSExpressionBuilder jscode = null;
		if (has_out_results) {
			var result_tmp = get_temp_variable_name ();
			js.stmt (jsvar (result_tmp).assign (jscall));
			var out_results_index = 0;
			if (has_result) {
				jscode = jsmember (result_tmp).element (0);
				out_results_index++;
			}
			foreach (var out_result in out_results) {
				if (!(out_result.value_type is NullType)) {
					js.stmt (jsexpr (get_jsvalue (out_result)).assign (jsmember (result_tmp).element (out_results_index++)));
				}
			}
		} else {
			jscode = jscall;
		}
		return jscode;
	}

	public void emit_control_flow_statement (ControlFlowStatement control) {
		if (current_closure_block != null && !is_in_loop (true)) {
			js.stmt (jsinteger (control).keyword ("return"));
		} else {
			switch (control) {
			case ControlFlowStatement.RETURN:
				js.stmt (jsmember ("result").keyword ("return"));
				break;
			case ControlFlowStatement.BREAK:
				js.stmt (jstext ("break"));
				break;
			case ControlFlowStatement.CONTINUE:
				js.stmt (jstext ("continue"));
				break;
			default:
				assert_not_reached ();
			}
		}
	}

	public string get_temp_variable_name () {
		return "_tmp%d_".printf (next_temp_var_id++);
	}

	public bool first_capital_naming (Symbol sym) {
		var cur = sym;
		while (cur != null) {
			var javascript = cur.get_attribute ("Javascript");
			if (javascript != null && javascript.get_bool ("first_capital")) {
				return true;
			}
			cur = cur.parent_symbol;
		}
		return false;
	}

	public bool camelcase_naming (Symbol sym) {
		var cur = sym;
		while (cur != null) {
			var javascript = cur.get_attribute ("Javascript");
			if (javascript != null && javascript.get_bool ("camelcase")) {
				return true;
			}
			cur = cur.parent_symbol;
		}
		return false;
	}

	/* copied from Vala.Symbol.lower_case_to_camel_case */
	public static string lower_case_to_camel_case (string lower_case, bool first_capital) {
		var result_builder = new StringBuilder ("");

		weak string i = lower_case;

		bool last_underscore = first_capital;
		while (i.length > 0) {
			unichar c = i.get_char ();
			if (c == '_') {
				last_underscore = true;
			} else if (c.isupper ()) {
				// original string is not lower_case, don't apply transformation
				return lower_case;
			} else if (last_underscore) {
				result_builder.append_unichar (c.toupper ());
				last_underscore = false;
			} else {
				result_builder.append_unichar (c);
			}
			
			i = i.next_char ();
		}

		return result_builder.str;
	}

	public string get_symbol_jsname (Symbol sym, string? name = null) {
		if (name == null) {
			name = sym.name;
		}
		if (camelcase_naming (sym)) {
			return lower_case_to_camel_case (name, first_capital_naming (sym));
		}
		return name;
	}

	public string get_variable_jsname (string name) {
		if (name[0] == '.') {
			// compiler-internal variable
			if (!variable_name_map.contains (name)) {
				variable_name_map.set (name, get_temp_variable_name ());
			}
			return variable_name_map.get (name);
		} else if (reserved_identifiers.contains (name)) {
			return "_%s_".printf (name);
		} else {
			return name;
		}
	}

	public void generate_construction_method (Class cl, CreationMethod m) {
		push_context (new EmitContext (m));
		var func = jsfunction ();
		push_function (func);
		if (!m.chain_up) {
			js.stmt (jsmember ("this._maja_init").call ());
		}
		m.accept_children (this);
		pop_context ();

		// declare function
		var jscode = jsmember (current_type_symbol.get_full_name ());
		if (m.name != ".new") {
			jscode.member (m.name);
		}
		push_context (decl_context);
		js.stmt (jsexpr(jscode).assign (func));
		if (m.name != ".new") {
			js.stmt (jsexpr(jscode).member("prototype").assign (jsmember(current_type_symbol.get_full_name ()).member("prototype")));
		}
		pop_context ();
	}

	public override LocalVariable create_local (DataType type) {
		return null;
	}

	public override TargetValue load_local (LocalVariable local) {
		return null;
	}

	public override void store_local (LocalVariable local, TargetValue value) {}
}

public class Maja.JSValue : TargetValue {
	public JSCode jscode;

	public JSValue (DataType? value_type = null, JSCode? jscode = null) {
		base (value_type);
		this.jscode = jscode;
	}
}
