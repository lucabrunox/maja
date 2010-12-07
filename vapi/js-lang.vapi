using Dova;

namespace Javascript {
	/* Global javascript variables */
	public List<any> arguments;
	public DOM.Document document;
	public Navigator navigator;
	public Window window;

	public string encodeURIComponent (string component);

	public class Object {
	}

	[Javascript (native_array = true)]
	public class Array<T> : Object {
		public Array (...);

		public void push<T> (T element);
		[Javascript (contains = true)]
		public bool contains (T element);
		[Javascript (getter = true)]
		public T get (int index);
		[Javascript (setter = true)]
		public void set (int index, T element);
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
