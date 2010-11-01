using Javascript;

namespace Dova {
	public class MarkupBuilder {
		public DOM.Document document;

		public MarkupBuilder (DOM.Document document) {
			this.document = document;
		}

		public DOM.Element createElement (string name, List<DOM.Node>? children = null, Map<string,any>? attributes = null) {
			var element = document.createElement (name);
			if (children != null) {
				foreach (var child in children) {
					element.appendChild (child);
				}
			}
			if (attributes != null) {
				foreach (var key in attributes.keys) {
					element.setAttribute (key, attributes[key]);
				}
			}
			return element;
		}

		public DOM.Element h1 (List<DOM.Node>? children = null, Map<string,any>? attributes = null) {
			return createElement ("h1", children, attributes);
		}

		public DOM.Node text (string text) {
			return document.createTextNode (text);
		}
	}
}
