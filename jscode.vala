public abstract class Maja.JSCode {
	public bool no_semicolon = false;
	public abstract void write (JSWriter writer);
}

public class Maja.JSExpressionBuilder : JSCode {
	private JSCode current;

	public JSExpressionBuilder (JSCode? initial = null) {
		this.current = initial;
	}

	public JSExpressionBuilder array () {
		var list = new JSList (true);
		if (current != null)
			list.add (current);
		current = list;
		return this;
	}

	public JSExpressionBuilder add_array_element (JSCode element) {
		var list = ((JSList) current);
		list.add (element);
		return this;
	}

	public JSExpressionBuilder keyword (string name) {
		current = new JSKeyword (name, current);
		return this;
	}

	public JSExpressionBuilder object_literal () {
		current = new JSObjectLiteral ();
		return this;
	}

	public JSExpressionBuilder string_literal (string text) {
		current = new JSText ("\"%s\"".printf (text));
		return this;
	}

	public JSExpressionBuilder member (string name) {
		return member_code (new JSText (name));
	}

	public JSExpressionBuilder member_code (JSCode member) {
		if (current == null)
			current = member;
		else
			current = new JSOperation (current, ".", member);
		return this;
	}

	public JSExpressionBuilder element (int n) {
		return element_code (new JSText (n.to_string ()));
	}

	public JSExpressionBuilder element_code (JSCode element) {
		current = new JSElementAccess (current, element);
		return this;
	}

	public JSExpressionBuilder call (JSCode? arguments = null) {
		current = new JSCall (current, arguments);
		return this;
	}

	public JSExpressionBuilder call_new (JSCode? arguments = null) {
		call (arguments);
		keyword ("new");
		return this;
	}

	public JSExpressionBuilder bind (JSCode? instance = null) {
		var arg = instance;
		if (arg == null) {
			arg = new JSText ("this");
		}
		member ("bind").call (arg);
		return this;
	}

	public JSExpressionBuilder assign (JSCode code) {
		current = new JSOperation (current, " = ", code);
		return this;
	}

	public JSExpressionBuilder plus (JSCode code) {
		current = new JSOperation (current, " + ", code, true);
		return this;
	}

	public JSExpressionBuilder equal (JSCode code) {
		current = new JSOperation (current, " === ", code, true);
		return this;
	}

	public JSExpressionBuilder inequal (JSCode code) {
		current = new JSOperation (current, " != ", code, true);
		return this;
	}

	public JSExpressionBuilder minus (JSCode? code = null) {
		if (code == null)
			current = new JSOperation (current, "-");
		else
			current = new JSOperation (current, " - ", code, true);
		return this;
	}

	public JSExpressionBuilder lt (JSCode code) {
		current = new JSOperation (current, " < ", code, true);
		return this;
	}

	public JSExpressionBuilder gt (JSCode code) {
		current = new JSOperation (current, " > ", code, true);
		return this;
	}

	public JSExpressionBuilder le (JSCode code) {
		current = new JSOperation (current, " <= ", code, true);
		return this;
	}

	public JSExpressionBuilder ge (JSCode code) {
		current = new JSOperation (current, " >= ", code, true);
		return this;
	}

	public JSExpressionBuilder and (JSCode code) {
		current = new JSOperation (current, " && ", code, true);
		return this;
	}

	public JSExpressionBuilder or (JSCode code) {
		current = new JSOperation (current, " || ", code, true);
		return this;
	}

	public JSExpressionBuilder negate () {
		current = new JSOperation (current, "!");
		return this;
	}

	public JSExpressionBuilder increment () {
		current = new JSOperation (current, "++", null, false, true);
		return this;
	}

	public JSExpressionBuilder decrement () {
		current = new JSOperation (current, "--", null, false, true);
		return this;
	}

	public override void write (JSWriter writer) {
		current.write (writer);
	}
}

public class Maja.JSObjectLiteral : JSCode {
	public override void write (JSWriter writer) {
		writer.write_string ("{}");
	}
}

public class Maja.JSOperation : JSCode {
	public JSCode left;
	public JSCode right;
	public string operation;
	public bool needs_parens;
	public bool is_postfix;

	public JSOperation (JSCode left, string operation, JSCode? right = null, bool needs_parens = false, bool is_postfix = false) {
		this.left = left;
		this.operation = operation;
		this.right = right;
		this.needs_parens = needs_parens;
		this.is_postfix = is_postfix;
	}

	public override void write (JSWriter writer) {
		var left_parens = left is JSOperation && ((JSOperation)left).needs_parens;
		var right_parens = right is JSOperation && ((JSOperation)left).needs_parens;
		if (right == null) {
			if (!is_postfix)
				writer.write_string (operation);
			if (left_parens)
				writer.write_string ("(");
			left.write (writer);
			if (right_parens)
				writer.write_string (")");
			if (is_postfix)
				writer.write_string (operation);
		} else {
			if (left_parens)
				writer.write_string ("(");
			left.write (writer);
			if (left_parens)
				writer.write_string (")");
			writer.write_string (operation);
			if (right_parens)
				writer.write_string ("(");
			right.write (writer);
			if (right_parens)
				writer.write_string (")");
		}
	}
}

public class Maja.JSElementAccess : JSCode {
	public JSCode container;
	public JSCode element;

	public JSElementAccess (JSCode container, JSCode element) {
		this.container = container;
		this.element = element;
	}

	public override void write (JSWriter writer) {
		container.write (writer);
		writer.write_string ("[");
		element.write (writer);
		writer.write_string ("]");
	}
}

public class Maja.JSBlockBuilder : JSCode {
	public JSBlock current;

	public JSBlockBuilder (JSBlock block) {
		current = block;
	}

	public void stmt (JSCode code) {
		current.statements.add (code);
	}

	public void error (JSCode code) {
		var expr = new JSExpressionBuilder (new JSText ("Error"));
		expr.call_new (new JSList().add (code));
		current.statements.add (new JSKeyword ("throw", expr));
	}

	public void open_if (JSCode condition) {
		current = new JSBlock (current, "if", condition);
	}

	public void add_else () {
		current = new JSBlock (current.parent, "else");
	}

	public void open_try () {
		current = new JSBlock (current, "try");
	}

	public void open_catch (string variable_name) {
		current = new JSBlock (current.parent, "catch", new JSText (variable_name));
	}

	public void open_finally () {
		current = new JSBlock (current.parent, "finally");
	}

	public void open_while (JSCode condition) {
		current = new JSBlock (current, "while", condition);
	}

	public void close () {
		current = current.parent;
	}

	public void open_block () {
		current = new JSBlock (current, "function", new JSList (), true);
	}

	public override void write (JSWriter writer) {
		current.write (writer);
	}
}

public class Maja.JSKeyword : JSCode {
	public string keyword;
	public JSCode expr;

	public JSKeyword (string keyword, JSCode expr) {
		this.keyword = keyword;
		this.expr = expr;
	}

	public override void write (JSWriter writer) {
		writer.write_string (keyword);
		writer.write_string (" ");
		expr.write (writer);
	}
}

public class Maja.JSBlock : JSCode {
	public JSBlock parent;
	public Gee.LinkedList<JSCode> statements = new Gee.LinkedList<JSCode> ();
	public string keyword;
	public JSCode expr;
	public bool call_function;

	public JSBlock (JSBlock? parent = null, string? keyword = null, JSCode? expr = null, bool call_function = false) {
		if (parent != null) {
			this.parent = parent;
			parent.statements.add (this);
		}
		this.no_semicolon = true;
		this.keyword = keyword;
		this.expr = expr;
		this.call_function = call_function;
	}

	public override void write (JSWriter writer) {
		if (keyword != null) {
			writer.write_string (keyword);
			writer.write_string (" ");
			if (expr != null) {
				writer.write_string ("(");
				expr.write (writer);
				writer.write_string (")");
			}
			writer.write_begin_block ();
		}
		foreach (var code in statements) {
			writer.write_indent ();
			code.write (writer);
			if (!code.no_semicolon)
				writer.write_string (";");
			writer.write_newline ();
		}
		if (keyword != null)
			writer.write_end_block ();
		if (call_function)
			writer.write_string ("();");
	}
}

public class Maja.JSText : JSCode {
	public string text;

	public JSText (string text) {
		this.text = text;
	}

	public override void write (JSWriter writer) {
		writer.write_string (text);
	}
}

public class Maja.JSList : JSCode {
	public Gee.LinkedList<JSCode> elements = new Gee.LinkedList<JSCode>();
	public bool is_array;

	public JSList (bool is_array = false) {
		this.is_array = is_array;
	}

	public JSList add (JSCode code) {
		elements.add (code);
		return this;
	}

	public JSList add_string (string name) {
		return add (new JSText (name));
	}

	public override void write (JSWriter writer) {
		if (is_array)
			writer.write_string ("[");
		var first = true;
		foreach (var param in elements) {
			if (!first)
				writer.write_string (", ");
			else
				first = false;
			param.write (writer);
		}
		if (is_array)
			writer.write_string ("]");
	}
}

public class Maja.JSObject : JSCode {
	public Gee.HashMap<JSCode,JSCode> elements = new Gee.HashMap<JSCode,JSCode>();

	public JSObject add (JSCode key, JSCode value) {
		elements[key] = value;
		return this;
	}

	public override void write (JSWriter writer) {
		writer.write_string ("{");
		var first = true;
		foreach (var entry in elements.entries) {
			if (!first)
				writer.write_string (", ");
			else
				first = false;
			entry.key.write (writer);
			writer.write_string (": ");
			entry.value.write (writer);
		}
		writer.write_string ("}");
	}
}

public class Maja.JSCall : JSCode {
	public JSCode expr;
	public JSCode arguments;

	public JSCall (JSCode expr, JSCode? arguments = null) {
		this.expr = expr;
		this.arguments = arguments;
	}

	public override void write (JSWriter writer) {
		expr.write (writer);
		writer.write_string (" (");
		if (arguments != null)
			arguments.write (writer);
		writer.write_string (")");
	}
}

public class Maja.JSFile : JSBlock {
	public bool store (string filename, string? source_filename, bool write_version, bool line_directives, string? begin_decls = null, string? end_decls = null) {
		var writer = new JSWriter (filename, source_filename);
		if (!writer.open (write_version)) {
			return false;
		}

		this.write (writer);

		writer.close ();

		return true;
	}
}
