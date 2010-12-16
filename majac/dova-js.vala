using Javascript;

namespace Dova {
	public class HTMLBuilder {
		public DOM.Document document;

		public HTMLBuilder (DOM.Document document) {
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

		public DOM.Element h1 (string? content = null, List<DOM.Node>? children = null, Map<string,any>? attributes = null, Map<string,EventCallback>? events = null) {
			var new_children = prepend_text (children, content);
			return create_element ("h1", new_children, attributes, events);
		}

		public DOM.Element div (List<DOM.Node>? children = null, Map<string,any>? attributes = null, Map<string,EventCallback>? events = null) {
			return create_element ("div", children, attributes, events);
		}

		public DOM.Element input (string? type = null, List<DOM.Node>? children = null, Map<string,any>? attributes = null, Map<string,EventCallback>? events = null) {
			var new_attributes = merge_attributes (attributes, {"type": type});
			return create_element ("input", children, new_attributes, events);
		}

		public DOM.Element textfield (List<DOM.Node>? children = null, Map<string,any>? attributes = null, Map<string,EventCallback>? events = null) {
			return input ("text", children, attributes, events);
		}

		public DOM.Element passwordfield (List<DOM.Node>? children = null, Map<string,any>? attributes = null, Map<string,EventCallback>? events = null) {
			return input ("password", children, attributes, events);
		}

		public DOM.Element button (List<DOM.Node>? children = null, Map<string,any>? attributes = null, Map<string,EventCallback>? events = null) {
			return input ("button", children, attributes, events);
		}

		public DOM.Element select (List<DOM.Node>? children = null, Map<string,any>? attributes = null, Map<string,EventCallback>? events = null) {
			return create_element ("select", children, attributes, events);
		}

		public DOM.Element option (List<DOM.Node>? children = null, Map<string,any>? attributes = null, Map<string,EventCallback>? events = null) {
			return create_element ("option", children, attributes, events);
		}

		public DOM.Element br (List<DOM.Node>? children = null, Map<string,any>? attributes = null, Map<string,EventCallback>? events = null) {
			return create_element ("br", children, attributes, events);
		}

		public DOM.Element hr (List<DOM.Node>? children = null, Map<string,any>? attributes = null, Map<string,EventCallback>? events = null) {
			return create_element ("hr", children, attributes, events);
		}

		public DOM.Element em (string? content = null, List<DOM.Node>? children = null, Map<string,any>? attributes = null, Map<string,EventCallback>? events = null) {
			var new_children = prepend_text (children, content);
			return create_element ("em", new_children, attributes, events);
		}

		public DOM.Element strong (string? content = null, List<DOM.Node>? children = null, Map<string,any>? attributes = null, Map<string,EventCallback>? events = null) {
			var new_children = prepend_text (children, content);
			return create_element ("strong", new_children, attributes, events);
		}

		public DOM.Element span (List<DOM.Node>? children = null, Map<string,any>? attributes = null, Map<string,EventCallback>? events = null) {
			return create_element ("span", children, attributes, events);
		}

		public DOM.Element table (List<DOM.Node>? children = null, Map<string,any>? attributes = null, Map<string,EventCallback>? events = null) {
			return create_element ("table", children, attributes, events);
		}

		public DOM.Element tbody (List<DOM.Node>? children = null, Map<string,any>? attributes = null, Map<string,EventCallback>? events = null) {
			return create_element ("tbody", children, attributes, events);
		}

		public DOM.Element tr (List<DOM.Node>? children = null, Map<string,any>? attributes = null, Map<string,EventCallback>? events = null) {
			return create_element ("tr", children, attributes, events);
		}

		public DOM.Element td (List<DOM.Node>? children = null, Map<string,any>? attributes = null, Map<string,EventCallback>? events = null) {
			return create_element ("td", children, attributes, events);
		}

		public DOM.Element th (string? content = null, List<DOM.Node>? children = null, Map<string,any>? attributes = null, Map<string,EventCallback>? events = null) {
			var new_children = prepend_text (children, content);
			return create_element ("th", new_children, attributes, events);
		}

		public DOM.Element form (string? action = null, List<DOM.Node>? children = null, string? method = "POST", Map<string,any>? attributes = null, Map<string,EventCallback>? events = null) {
			var new_attributes = merge_attributes (attributes, {"action": action, "method": method});
			return create_element ("form", children, new_attributes, events);
		}

		public DOM.Node text (string text) {
			return document.create_text_node (text);
		}

		Map<string,any> merge_attributes (Map<string,any>? attributes, Map<string,any> replacement) {
			if (attributes == null) {
				return replacement;
			}
			var res = attributes;
			foreach (var key in replacement.keys) {
				var value = replacement[key];
				if (value != null) {
					res = res.set (key, replacement[key]);
				}
			}
			return res;
		}

		List<DOM.Node>? prepend_text (List<DOM.Node>? children, string? content) {
			if (children == null && content == null) {
				return null;
			}
			var res = [text (content)];
			if (children != null) {
				res = res.concat (children);
			}
			return res;
		}
	}
}
