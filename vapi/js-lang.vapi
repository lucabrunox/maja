using Dova;

namespace Javascript {
	/* Global javascript variables */
	public any[] arguments;
	public DOM.Document document;
	public Navigator navigator;
	public Window window;

	public string encodeURIComponent (string component);

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
		[Javascript (getter = true)]
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
		public int setTimeout (Callback callback, int interval);
		public void open (string url, string mode);
	}

	namespace DOM {
		public class Document {
			public Element createElement (string name);
			public Node createTextNode (string text);
			public Element[] getElementsByTagName (string name);
		}

		public class Node {
			public void appendChild (Node node);
		}

		public class Element : Node {
			public void setAttribute (string name, any value);
		}
	}
}
