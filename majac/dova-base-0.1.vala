public abstract class any {
	// allow nullable this
	public virtual bool equals (any? other) {
		if (!(this is Javascript.Object) || (!("equals" in ((Javascript.Object) this)))) {
			return ((Javascript.Object) this).js_equals (other);
		}
		return ((Javascript.Object) this).equals (other);
	}

	// allow nullable this
	public abstract string to_string ();
}

public abstract class Dova.Type {
}

public class Dova.Object : any {
	public override bool equals (any? other) {
		return (this == other);
	}

	public override string to_string () {
		return "Object";
	}
}

[BooleanType]
public struct bool {
	public string to_string () {
		return this ? "true" : "false";
	}
}

public class Dova.Error {
	public string message { get; set; }

	public Error (string message) {
		this.message = message;
	}

	public string to_string () {
		return message;
	}
}

// to_string() is hardcoded for all basic types
[IntegerType (rank = 3, width = 8, signed = false)]
public struct byte {
}

[IntegerType (rank = 7, width = 32)]
public struct char {
	public extern string to_string ();
}

[IntegerType (rank = 2, width = 8)]
public struct int8 {
}

[IntegerType (rank = 3, width = 8, signed = false)]
public struct uint8 {
}

[IntegerType (rank = 4, width = 16)]
public struct int16 {
}

[IntegerType (rank = 5, width = 16, signed = false)]
public struct uint16 {
}

[IntegerType (rank = 6, width = 32)]
public struct int32 {
}

[IntegerType (rank = 7, width = 32, signed = false)]
public struct uint32 {
}

[IntegerType (rank = 8)]
public struct int {
}

[IntegerType (rank = 9, signed = false)]
public struct uint {
}

[IntegerType (rank = 8, width = 64)]
public struct int64 {
}

[IntegerType (rank = 9, width = 64, signed = false)]
public struct uint64 {
}

[FloatingType (rank = 1)]
public struct float {
}

[FloatingType (rank = 2, width = 64)]
public struct double {
}

public class Dova.Value : any {
	protected Value () {
	}

	public override bool equals (any? other) {
		return false;
	}

	public override string to_string () {
		return "";
	}
}

namespace Dova {
	public void assert (bool condition, string? message = null) {
		if (!condition) {
			if (message != null) {
				throw new Error ("assertion failed: " + message);
			} else {
				throw new Error ("assertion failed");
			}
		}
	}

	public void assert_compare (string expr, string v1, string cmp, string v2) {
		assert (false, "($expr): ($v1 $cmp $v2)");
	}

	[NoReturn]
	public void assert_not_reached () {
		assert (false);
	}
}

public class string : Dova.Value {
	// FIXME: length is not in bytes
	// hardcoded in maja
	// FIXME: Vala must allow get only for extern

	public extern int length { get; private set; }

	// slice is in javascript
	public extern string slice (int start_index, int end_index);

	// concat is in javascript
	public extern string concat (string other);

	public bool contains (string value) {
		return index_of (value) >= 0;
	}

	public static int compare (string? s1, string? s2) {
		if (s1 == null) {
			if (s2 == null) {
				return 0;
			} else {
				return -1;
			}
		} else if (s2 == null) {
			return 1;
		}
		if (s1 < s2) {
			return -1;
		} else if (s1 > s2) {
			return 1;
		} else {
			return 0;
		}
	}

	public bool starts_with (string value) {
		return slice (0, value.length) == value;
	}

	public bool ends_with (string value) {
		return slice (length-value.length, length) == value;
	}

	// split is in javascript
	public extern List<string> split (string delimiter);

	public string join (List<string> list) {
		result = "";

		if (list.length > 0) {
			result += list[0];
			for (int i = 1; i < list.length; i++) {
				result += this;
				result += list[i];
			}
		}
	}

	public override string to_string () {
		return this;
	}

	// equals is hardcoded in javascript
	// FIXME: what's the point of "new" in static methods?
	public extern static new bool equals (string? a, string? b);

	// get() is hardcoded

	// index_of() is hardcoded as javascript indexOf()
	public extern int index_of (string needle, int start_index = 0, int end_index = -1);

	public int index_of_char (char c, int start_index = 0, int end_index = -1) {
		return index_of (c.to_string (), start_index, end_index);
	}

	// last_index_of() is hardcoded as javascript lastIndexOf()
	public extern int last_index_of (string needle, int start_index = 0, int end_index = -1);

	public int last_index_of_char (char c, int start_index = 0, int end_index = -1) {
		return last_index_of (c.to_string (), start_index, end_index);
	}

	// to_lower is hardcoded as toLowerCase

	// to_upper is hardcoded as toUpperCase

	// replace() is native
	public extern string replace (string old, string replacement);
}

public class Dova.List<T> : Object {
	public extern int length { get; private set; }
	public extern T get (int index);
}

public class Dova.Tuple<T> : Object {
	public extern int length { get; private set; }
	public extern T get (int index);
}
public abstract class Dova.Iterator<T> : Dova.Object {
	public Iterator ();
	public abstract T get ();
	public abstract bool next ();
}
