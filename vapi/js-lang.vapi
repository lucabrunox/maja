[Javascript (camelcase = true)]
namespace Javascript {
	/* Global javascript variables */
	public any[] arguments;
	public DOM.Document document;
	public Navigator navigator;
	public Window window;

	[Javascript (name = "encodeURIComponent")]
	public string encode_uri_component (string component);

	public class Object {
		public Object ();
		[Javascript (contains = true)]
		public bool contains (any key);
		public new bool equals (any? other);
		[Javascript (equals = true)]
		public bool js_equals (any? other);
		[Javascript (copy = true)]
		public T copy<T> ();
		[Javascript (getter = true)]
		public any get (any key);
		[Javascript (setter = true)]
		public void set (any key, any value);
		[Javascript (delete = true)]
		public void delete (any key);
	}

	[Javascript (native_array = true)]
	public class Array<T> : Object {
		public Array (...);

		public void push<T> (T element);
		[Javascript (contains = true)]
		public new bool contains (T element);
		[Javascript (getter = true)]
		public T get (int index);
		[Javascript (setter = true)]
		public void set (int index, T element);
		[Javascript (simple_field = true)]
		public int length { get; }
		public string join (string delimiter);
	}

	public class String {
		public string substring (int from, int? to = null);
	}

	public class Event {
	}

	public delegate void Callback ();
	public delegate bool EventCallback (Event? event);

	public void alert (any object);

	public class RegExp {
		public RegExp (string pattern, string modifiers);
		public bool test (string str);
	}

	public class Navigator {
		public string userAgent;
	}

	public class Window {
		[Javascript (simple_field = true)]
		public Location location;
		public int set_timeout (Callback callback, int interval);
		public void open (string url, string mode);
	}

	public class Location {
		[Javascript (simple_field = true)]
		public string href;
	}

	namespace DOM {
		public class Document {
			public Element create_element (string name);
			public Node create_text_node (string text);
			public Element[] get_elements_by_tag_name (string name);
		}

		public class Node {
			public void append_child (Node node);
		}

		public class Element : Node {
			public void set_attribute (string name, any value);
		}
	}
}
