using Dova;

namespace Javascript {
	/* Global javascript variables */
	public List<any> arguments;
	public DOM.Document document;

	public class Event {
	}

	public delegate bool EventCallback (Event event);

	public void alert (any object);

	namespace DOM {
		public class Document {
			public Element createElement (string name);
			public Node createTextNode (string text);
		}

		public class Node {
			public void appendChild (Node node);
		}

		public class Element : Node {
			public void setAttribute (string name, any value);
		}
	}
}
