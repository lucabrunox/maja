using Javascript;

namespace Dova {
	public class MarkupBuilder {
		public DOM.Document document;

		public MarkupBuilder (DOM.Document document) {
			this.document = document;
		}

		public DOM.Element create_element (string name, List<DOM.Node>? children = null, Map<string,any>? attributes = null) {
			var element = document.create_element (name);
			if (children != null) {
				foreach (var child in children) {
					element.append_child (child);
				}
			}
			if (attributes != null) {
				foreach (var key in attributes.keys) {
					element.set_attribute (key, attributes[key]);
				}
			}
			return element;
		}

		public DOM.Element h1 (List<DOM.Node>? children = null, Map<string,any>? attributes = null) {
			return create_element ("h1", children, attributes);
		}

		public DOM.Node text (string text) {
			return document.create_text_node (text);
		}
	}
}
