namespace qx {
	namespace ui {
		namespace basic {
			public class Atom : core.Widget {
			}
		}
		namespace container {
			public class Composite : core.Widget {
				public Composite ();
				public void add (core.LayoutItem child, Dova.Map<string,any>? options = null);
			}
		}
		namespace form {
			public class Button : basic.Atom {
				public Button (string label, string? icon = null, Command? command = null);
			}

			public class Command {
				public Command (string shortcut);
			}
		}
		namespace core {
			public class LayoutItem {
				public string addListener (string type, [Javascript (has_this_parameter = true)] Javascript.EventCallback listener, bool capture = false);
			}
			public class Widget : LayoutItem {
			}
		}
	}
	namespace application {
		public class AbstractGUI {
			public ui.core.Widget getRoot ();
		}

		public class Standalone : AbstractGUI {
		}
	}
}
