public abstract class Maja.JSCode {
	public bool no_semicolon = false;
	public abstract void write (JSWriter writer);
}

public class Maja.JSExpressionBuilder : JSCode {
	private JSCode current;

	public JSExpressionBuilder (JSCode? initial = null) {
		this.current = initial;
	}

	public JSExpressionBuilder text (string text) {
		current = new JSText (text);
		return this;
	}

	public JSExpressionBuilder keyword (string name) {
		current = new JSKeyword (name, current);
		return this;
	}

	public JSExpressionBuilder null_literal () {
		current = new JSText ("null");
		return this;
	}

	public JSExpressionBuilder object () {
		current = new JSObjectLiteral ();
		return this;
	}

	public JSExpressionBuilder member (string name) {
		if (current == null)
			current = new JSText (name);
		else
			current = new JSOperation (current, ".", new JSText (name));
		return this;
	}

	public JSExpressionBuilder call (JSList? arguments = null) {
		current = new JSCall (current, arguments);
		return this;
	}

	public JSExpressionBuilder assign (JSCode code) {
		current = new JSOperation (current, "=", code);
		return this;
	}

	public JSExpressionBuilder plus (JSCode code) {
		current = new JSOperation (current, "+", code, true);
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

	public JSOperation (JSCode left, string operation, JSCode? right = null, bool needs_parens = false) {
		this.left = left;
		this.operation = operation;
		this.right = right;
		this.needs_parens = needs_parens;
	}

	public override void write (JSWriter writer) {
		var left_parens = left is JSOperation && ((JSOperation)left).needs_parens;
		var right_parens = right is JSOperation && ((JSOperation)left).needs_parens;
		if (right == null) {
			writer.write_string (operation);
			if (left_parens)
				writer.write_string ("(");
			left.write (writer);
			if (right_parens)
				writer.write_string (")");
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

public class Maja.JSBlockBuilder : JSCode {
	private JSBlock current;

	public JSBlockBuilder (JSBlock block) {
		current = block;
	}

	public JSList parameters () {
		return new JSList ();
	}

	public void stmt (JSCode code) {
		current.statements.add (code);
	}

	public void open_if (JSCode condition) {
		current = new JSBlock (current, "if", condition);
	}

	public void add_else () {
		current = new JSBlock (current.parent, "else");
	}

	public void add_else_if (JSCode condition) {		
		current = new JSBlock (current.parent, "else if", condition);
	}

	public void open_while (JSCode condition) {
		current = new JSBlock (current, "while", condition);
	}

	public void end () {
		current = current.parent;
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

	public JSBlock (JSBlock? parent = null, string? keyword = null, JSCode? expr = null) {
		if (parent != null)
			parent.statements.add (this);
		this.no_semicolon = true;
		this.keyword = keyword;
		this.expr = expr;
	}

	public override void write (JSWriter writer) {
		if (keyword != null) {
			writer.write_string (keyword);
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
	public Gee.LinkedList<string> parameters_list = new Gee.LinkedList<string>();

	public JSList add (string name) {
		parameters_list.add (name);
		return this;
	}

	public override void write (JSWriter writer) {
		var first = true;
		foreach (var param in parameters_list) {
			if (!first)
				writer.write_string (", ");
			else
				first = false;
			writer.write_string (param);
		}
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
		writer.write_string ("(");
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
