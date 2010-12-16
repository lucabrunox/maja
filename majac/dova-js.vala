using Javascript;

namespace Dova {
	public class MarkupBuilder {
		public DOM.Document document;

		public MarkupBuilder (DOM.Document document) {
			this.document = document;
		}

		public DOM.Element create_element (string name, List<DOM.Node>? children = null, Map<string,any>? attributes = null, Map<string,EventCallback>? events = null) {
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
			if (events != null) {
				foreach (var key in events.keys) {
					var value = events[key];
					element[key] = value;
				}
			}
			return element;
		}

		public DOM.Element h1 (List<DOM.Node>? children = null, Map<string,any>? attributes = null, Map<string,EventCallback>? events = null) {
			return create_element ("h1", children, attributes, events);
		}

		public DOM.Element div (List<DOM.Node>? children = null, Map<string,any>? attributes = null, Map<string,EventCallback>? events = null) {
			return create_element ("div", children, attributes, events);
		}

		public DOM.Element input (List<DOM.Node>? children = null, Map<string,any>? attributes = null, Map<string,EventCallback>? events = null) {
			return create_element ("input", children, attributes, events);
		}

		public DOM.Element button (List<DOM.Node>? children = null, Map<string,any>? attributes = null, Map<string,EventCallback>? events = null) {
			var new_attributes = attributes.set ("type", "button");
			return input (children, new_attributes, events);
		}

		public DOM.Node text (string text) {
			return document.create_text_node (text);
		}
	}
}
