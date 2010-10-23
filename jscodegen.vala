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
	public EmitContext init_emit_context = new EmitContext ();

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
	Set<string> reserved_identifiers;
	
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
		reserved_identifiers = new HashSet<string> (str_hash, str_equal);

        // TODO:
		reserved_identifiers.add ("this");
		reserved_identifiers.add ("for");
		reserved_identifiers.add ("while");

		// reserved for Maja naming conventions
		reserved_identifiers.add ("error");
		reserved_identifiers.add ("result");
	}

	public override void emit (CodeContext context) {
		this.context = context;

		root_symbol = context.root;

		bool_type = new BooleanType ((Struct) root_symbol.scope.lookup ("bool"));
		char_type = new IntegerType ((Struct) root_symbol.scope.lookup ("char"));
		string_type = new ObjectType ((Class) root_symbol.scope.lookup ("string"));

		/* we're only interested in non-pkg source files */
		var source_files = context.get_source_files ();
		foreach (SourceFile file in source_files) {
			if (file.file_type == SourceFileType.SOURCE ||
			    (context.header_filename != null && file.file_type == SourceFileType.FAST)) {
				file.accept (this);
			}
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
		jsfile = new JSFile ();
		jsdecl = new JSBlockBuilder (jsfile);

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

		var csource_filename = source_file.get_csource_filename ();
		var jssource_filename = "%s.js".printf (csource_filename.ndup (csource_filename.length - ".vala.c".length));
		if (!jsfile.store (jssource_filename, source_file.filename, context.version_header, context.debug)) {
			Report.error (null, "unable to open `%s' for writing".printf (jssource_filename));
		}

		jsfile = null;
	}

	public override void visit_class (Class cl) {
		push_context (new EmitContext (cl));
		// init function
		init_emit_context = new EmitContext (cl);
		push_context (init_emit_context);
		var init_func = jsfunction ();
		push_function (init_func);
		pop_context ();

		jsdecl.stmt (jsmember(cl.name).member("prototype._maja_init").assign (init_func));

		cl.accept_children (this);
		pop_context ();
	}

	public override void visit_method (Method m) {
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
		m.accept_children (this);
		pop_context ();

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

	public override void visit_formal_parameter (FormalParameter param) {
		if (param.direction == ParameterDirection.IN) {
			// never assign a value directly to a parameter in javascript
			var param_list = (JSList) js.current.expr;
			param_list.add_string ("param_"+param.name);
			// initialize default
			// declare local variable for parameter
			js.stmt (jsvar(param.name));
			js.open_if (jsmember("param_"+param.name).inequal (jsundefined ()));
			if (!param.variable_type.nullable) {
				js.open_if (jsmember("param_"+param.name).equal (jsnull ()));
				js.error (jsstring ("Unexpected null parameter '"+param.name+"'"));
				js.end ();
			}
			js.stmt (jsmember(param.name).assign (jsmember("param_"+param.name)));
			js.add_else ();
			if (param.initializer != null) {
				param.initializer.emit (this);
				js.stmt (jsmember(param.name).assign (get_jsvalue (param.initializer)));
			} else {
				js.error (jsstring ("Undefined parameter '"+param.name+"'"));
			}
			js.end ();
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
		emit_context.push_symbol (block);
		foreach (var stmt in block.get_statements ()) {
			stmt.emit (this);
		}
		emit_context.pop_symbol ();
	}

	public override void visit_declaration_statement (DeclarationStatement stmt) {
		stmt.declaration.accept (this);
	}

	public override void visit_local_variable (LocalVariable local) {
		var decl = jsvar (local.name);
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

		JSCode jscode = null;
		if (expr.operator == BinaryOperator.PLUS)
			jscode = jsexpr(jsleft).plus (jsright);
		set_jsvalue (expr, jscode);
	}

	public override void visit_integer_literal (IntegerLiteral expr) {
		set_jsvalue (expr, jstext (expr.value + expr.type_suffix));
	}

	public override void visit_return_statement (ReturnStatement stmt) {
		var m = current_method;
		JSExpressionBuilder result = null;
		if (stmt.return_expression != null) {
			stmt.return_expression.emit (this);
			result = jsexpr (get_jsvalue (stmt.return_expression));
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
			js.stmt (jsvar ("_maja_result").assign (result));
			js.stmt (jsmember ("_maja_result").keyword ("return"));
		}
	}

	public override void visit_member_access (MemberAccess ma) {
		JSCode jscode = jsmember (ma.member_name);
		var expr = ma.inner as MemberAccess;
		while (expr != null) {
			jscode = jsmember (expr.member_name).access (jscode);
			expr = expr.inner as MemberAccess;
		}
		set_jsvalue (ma, jscode);
	}

	public override void visit_field (Field field) {
		if (field.binding == MemberBinding.INSTANCE) {
			push_context (init_emit_context);
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
		js.stmt (get_jsvalue (stmt.expression));
	}

	public override void visit_object_creation_expression (ObjectCreationExpression expr) {
		var sym = expr.type_reference.data_type;
		var jscode = jsmember (sym.get_full_name ());
		if (expr.member_name.symbol_reference is CreationMethod)
			jscode.member (expr.member_name.symbol_reference.name);
		jscode.call_new (generate_jslist (expr.get_argument_list ()));
		set_jsvalue (expr, jscode);
	}

	public override void visit_assignment (Assignment expr) {
		expr.left.emit (this);
		expr.right.emit (this);
		set_jsvalue (expr, jsexpr (get_jsvalue (expr.left)).assign (get_jsvalue (expr.right)));
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

	public JSExpressionBuilder jsundefined () {
		return jstext ("undefined");
	}

	public JSExpressionBuilder jsvar (string name) {
		var result = jsmember (name);
		result.keyword ("var");
		return result;
	}

	public JSExpressionBuilder jsstring (string value) {
		return jstext ("\"%s\"".printf (value));
	}

	public JSList generate_jslist (Vala.List<Expression> expressions) {
		var list = new JSList ();
		foreach (var arg in expressions) {
			list.add (get_jsvalue (arg));
		}
		return list;
	}

	public LocalVariable get_temp_variable (DataType type, bool value_owned = true, CodeNode? node_reference = null, bool init = true) {
		var var_type = type.copy ();
		var_type.value_owned = value_owned;
		var local = new LocalVariable (var_type, "_tmp%d_".printf (next_temp_var_id));
		local.no_init = !init;

		if (node_reference != null) {
			local.source_reference = node_reference.source_reference;
		}

		next_temp_var_id++;

		return local;
	}

	public void emit_temp_var (LocalVariable local) {
		JSCode rhs = null;
		if (local.initializer != null) {
			rhs = get_jsvalue (local.initializer);
		} else {
			rhs = jsnull ();
		}
		js.stmt (jsvar(local.name).assign(rhs));
	}
}

public class Maja.JSValue : TargetValue {
	public JSCode jscode;

	public JSValue (DataType? value_type = null, JSCode? jscode = null) {
		base (value_type);
		this.jscode = jscode;
	}
}
