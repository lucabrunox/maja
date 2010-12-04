using Dova;

namespace Javascript {
	/* Global javascript variables */
	public List<any> arguments;
	public DOM.Document document;
	public Navigator navigator;
	public Window window;

	public class Event {
	}

	public delegate void Callback ();
	public delegate bool EventCallback (Event event);

	public void alert (any object);

	public class Navigator {
		public string userAgent;
	}

	public class Window {
		public int setTimeout (Callback callback, int interval);
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
