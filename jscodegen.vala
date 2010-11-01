/* valaccodebasemodule.vala
 *
 * Copyright (C) 2006-2010  Jürg Billeter
 * Copyright (C) 2006-2008  Raffaele Sandrini
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 * 	Jürg Billeter <j@bitron.ch>
 * 	Raffaele Sandrini <raffaele@sandrini.ch>
 */

using Vala;

/**
 * Code visitor generating C Code.
 */
public class Maja.JSCodeGenerator : CodeGenerator {
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

	public JSFile jsfile;
	public JSBlockBuilder jsdecl;

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

	public Block? current_closure_block {
		get {
			return next_closure_block (current_symbol);
		}
	}

	public unowned Block? next_closure_block (Symbol sym) {
		unowned Block block = null;
		while (true) {
			block = sym as Block;
			if (!(sym is Block || sym is Method)) {
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

	public EmitContext class_init_context;
	public EmitContext base_init_context;
	public EmitContext class_finalize_context;
	public EmitContext base_finalize_context;
	public EmitContext instance_init_context;
	public EmitContext instance_finalize_context;
	
	public JSBlockBuilder js { get { return emit_context.js; } }

	/* (constant) hash table with all reserved identifiers in the generated code */
	Set<string> reserved_identifiers = new HashSet<string> (str_hash, str_equal);
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

		static_method_mapping["string.contains"] = "string.prototype.contains";
		static_method_mapping["any.to_string"] = "Dova.to_string";

		native_mapping["string.index_of"] = "indexOf";
	}

	public override void emit (CodeContext context) {
		this.context = context;

		root_symbol = context.root;

		jsfile = new JSFile ();

		/* we're only interested in non-pkg source files */
		var source_files = context.get_source_files ();
		foreach (SourceFile file in source_files) {
			if (file.file_type == SourceFileType.SOURCE ||
			    (context.header_filename != null && file.file_type == SourceFileType.FAST)) {
				file.accept (this);
			}
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
		emit_context.js = emit_context.js_stack.poll_head ();
	}

	public bool add_symbol_declaration (CCodeFile decl_space, Symbol sym, string name) {
		if (decl_space.add_declaration (name)) {
			return true;
		}
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

	public override void visit_source_file (SourceFile source_file) {
		var jsblock = new JSBlock ();
		jsblock.no_semicolon = true;
		jsdecl = new JSBlockBuilder (jsblock);

		source_file.accept_children (this);

		if (context.report.get_errors () > 0) {
			return;
		}

		/* For fast-vapi, we only wanted the header declarations
		 * to be emitted, so bail out here without writing the
		 * C code output.
		 */
		if (source_file.file_type == SourceFileType.FAST) {
			return;
		}

		jsfile.statements.add (jsblock);
	}

	public override void visit_class (Class cl) {
		push_context (new EmitContext (cl));

		// constructor defines the class too
		generate_construction_method (cl, cl.default_construction_method as CreationMethod);
		if (cl.base_class != null) {
			jsdecl.stmt (jsdova().member("mixin").call (jslist().add (jsmember(cl.get_full_name()).member("prototype")).add (jsmember(cl.base_class.get_full_name()).member("prototype"))));
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

		jsdecl.stmt (jsmember(cl.name).member("prototype._maja_init").assign (init_func));

		cl.accept_children (this);
		pop_context ();
	}

	public override void visit_method (Method m) {
		if (m.external)
			return;

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
		jsdecl.stmt (def);
	}

	public override void visit_creation_method (CreationMethod m) {
		push_context (new EmitContext (m));

		var cl = current_class;
		if (cl == null || m == cl.default_construction_method)
			return;
		generate_construction_method (cl, m);

		pop_context ();
	}

	public override void visit_formal_parameter (FormalParameter param) {
		if (param.direction == ParameterDirection.IN) {
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
		/*if (current_symbol is Block) {
		  js.open_block ();
		  }*/
		emit_context.push_symbol (block);
		foreach (var stmt in block.get_statements ()) {
			stmt.emit (this);
		}
		emit_context.pop_symbol ();
		/*if (current_symbol is Block) {
		  js.close ();
		  }*/
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

		if (result != null) {
			if (current_return_type is VoidType) {
				js.stmt (jsvar ("result").assign (result));
			} else if (has_out_parameters) {
				js.stmt (jsmember ("result").assign (result));
			}
			js.stmt (jsmember ("result").keyword ("return"));
		}
	}

	public override void visit_member_access (MemberAccess ma) {
		JSCode jscode = null;

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
				jscode = jsexpr (get_jsvalue (ma.inner)).member (member_name);
			}
		} else {
			jscode = jsmember (member_name);
		}

		set_jsvalue (ma, jscode);
	}

	public override void visit_field (Field field) {
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
		set_jsvalue (expr, emit_method_call (expr.symbol_reference as CreationMethod, jscode, expr.get_argument_list (), null, expr));
	}

	public override void visit_assignment (Assignment expr) {
		expr.left.emit (this);
		expr.right.emit (this);
		set_jsvalue (expr, jsexpr(get_jsvalue (expr.left)).assign (get_jsvalue (expr.right)));
	}

	public override void visit_method_call (MethodCall expr) {
		Method m;
		if (expr.call.symbol_reference is Class)
			m = ((Class) expr.call.symbol_reference).default_construction_method;
		else
			m = (Method) expr.call.symbol_reference;
		bool has_out_parameters;
		var jscode = emit_method_call (m, jsexpr (get_jsvalue (expr.call)), expr.get_argument_list (), out has_out_parameters, expr);
		if (!(expr.parent_node is ExpressionStatement && has_out_parameters))
			set_jsvalue (expr, jscode);
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
		set_jsvalue (expr, jsdova().member("array").call (jssizes));
	}

	public override void visit_element_access (ElementAccess expr) {
		var jsindices = jslist ();
		foreach (var index in expr.get_indices ()) {
			jsindices.add (get_jsvalue (index));
		}
		set_jsvalue (expr, jsexpr (get_jsvalue (expr.container)).element_code (jsindices));
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
			if (!return_found)
				m.body.add_statement (new ReturnStatement ());
		}

		var func = jsfunction ();
		push_function (func);
		if (m.is_abstract) {
			js.error (jsstring ("Abstract method '%s' not implemented".printf (m.get_full_name())));
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

	public JSExpressionBuilder jsdova () {
		return jstext ("Dova");
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
		return jsdova().member("bind").call (jslist().add (scope ?? jsmember ("this")).add (func));
	}

	public JSExpressionBuilder jsstring (string value) {
		return jstext ("\"%s\"".printf (value));
	}

	public JSCode? emit_method_call (Method m, JSExpressionBuilder jscall, Vala.List<Expression> arguments, out bool has_out_results = false, CodeNode? node_reference = null) {
		var has_result = !(m.return_type is VoidType) || m is CreationMethod;
		Expression[] out_results = null;
		var jsargs = jslist ();

		var arg_it = arguments.iterator ();
		foreach (var param in m.get_parameters ()) {
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
			}
		}

		if (m is CreationMethod) {
			jscall.call_new (jsargs);
		} else {
			jscall.call (jsargs);
		}
		JSCode jscode = null;
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

	public string get_temp_variable_name () {
		return "_tmp%d_".printf (next_temp_var_id++);
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
		jsdecl.stmt (jsexpr(jscode).assign (func));
		if (m.name != ".new") {
			jsdecl.stmt (jsexpr(jscode).member("prototype").assign (jsmember(current_type_symbol.get_full_name ()).member("prototype")));
		}
	}
}

public class Maja.JSValue : TargetValue {
	public JSCode jscode;

	public JSValue (DataType? value_type = null, JSCode? jscode = null) {
		base (value_type);
		this.jscode = jscode;
	}
}
