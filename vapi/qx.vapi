[Javascript (camelcase = true)]
namespace qx {
	namespace event {
		namespace type {
			public class Event {
				public string type;
			}
		}
		public delegate void Callback (dynamic type.Event? e);
		public class Timer {
			public static Timer once ([Javascript (has_this_parameter = true)] Callback function, int timeout);
		}
	}
	namespace core {
		public class Setting {
			public static T get<T> (string key);
		}
		public class Object {
			public string tr (string str);
			public string add_listener (string type, [Javascript (has_this_parameter = true)] qx.event.Callback listener, bool capture = false);
			public void set_user_data (string key, any value);
			public T get_user_data<T> (string key);
		}
		public class Variant {
			public static bool is_set (string key, string variants);
		}
	}
	namespace ui {
		namespace splitpane {
			public class Pane : core.Widget {
				public Pane (string orientation = "horizontal");
				public void add (core.Widget widget, int? flex = null);
			}
		}
		namespace menu {
			public class Menu : core.Widget {
				public Menu ();
				public void add (core.LayoutItem child, Dova.Map<string,any>? options = null);
			}
			public class AbstractButton : core.Widget, form.IExecutable {
			}
			public class Button : AbstractButton {
				public Button (string label, string? icon = null, core.Command? command = null, Menu? menu = null);
			}
			public class RadioButton : AbstractButton {
				public bool value;

				public RadioButton (string label, Menu? menu = null);
			}
		}
		namespace tree {
			public class Tree : core.scroll.AbstractScrollArea {
				public AbstractTreeItem root;
				public Dova.List<AbstractTreeItem> selection;

				public Tree ();

				public AbstractTreeItem get_next_node_of (AbstractTreeItem tree_item, bool invisible = true);
				public AbstractTreeItem get_previous_node_of (AbstractTreeItem tree_item, bool invisible = true);
				public Dova.List<AbstractTreeItem> get_items (bool recursive = false, bool invisible = true);
			}
			public class AbstractTreeItem : core.Widget {
				public Tree? tree { get; }
				public bool open;
				public AbstractTreeItem parent;
				public Dova.List<AbstractTreeItem> get_items (bool recursive = true, bool invisible = true, bool ignore_first = true);
			}
			public class TreeFolder : AbstractTreeItem {
				public TreeFolder (string? label = null);
			}
			public class TreeFile : AbstractTreeItem {
			}
		}
		namespace toolbar {
			public class ToolBar : core.Widget {
				public ToolBar ();
				public void add (core.LayoutItem child, Dova.Map<string,any>? options = null);
				public void add_spacer ();
			}
			public class Part : core.Widget {
				public Part ();
				public void add (core.LayoutItem child, Dova.Map<string,any>? options = null);
			}
			public class Button : form.Button {
				public Button (string label, string? icon = null, core.Command? command = null);
			}
			public class MenuButton : form.Button {
				public MenuButton (string label, string? icon = null, menu.Menu? menu = null);
			}
			public class RadioButton : basic.Atom {
				public RadioButton (string label, string? icon = null);
			}
		}
		namespace embed {
			public class AbstractIframe : core.Widget {
				public Javascript.Window window { get; }
				public string source;
				public void reload ();
			}
			public class Iframe : AbstractIframe {
			}
		}
		namespace basic {
			public class Atom : core.Widget {
			}
			public class Label : core.Widget {
				public string text_align;

				public Label (string value);
			}
			public class Image : core.Widget {
				public Image (string? source = null);
			}
		}
		namespace container {
			public class Composite : core.Widget {
				public layout.Abstract layout;

				public Composite (layout.Abstract? layout = null);
				public void add (core.LayoutItem child, Dova.Map<string,any>? options = null);
			}
		}
		namespace form {
			public class Button : basic.Atom {
				public Button (string label, string? icon = null, core.Command? command = null);
			}
			public class RadioGroup : qx.core.Object {
				public bool allow_empty_selection;
				public RadioGroup (...);
				public void add (...);
			}
			public interface IExecutable {
				public core.Command command { get; set; }
			}
			public class AbstractField : core.Widget {
				public bool live_update;
				public string placeholder;
			}
			public class TextField : AbstractField {
				public TextField (string? value = null);
			}
		}
		namespace core {
			namespace scroll {
				public class AbstractScrollArea : Widget {
				}
			}
			public class Command : qx.core.Object {
				public Command (string shortcut);
			}
			public class LayoutItem : qx.core.Object {
				public int min_width;
				public int width;
			}
			public class Widget : LayoutItem {
				public string appearance;
				public string visibility;
				public string tool_tip_text;
				public string decorator;
				public string background_color;
				public bool enabled;

				public bool is_visible ();
				public void exclude ();
			}
			public class Spacer : LayoutItem {
				public Spacer (int? width = null, int? height = null);
			}
		}
		namespace layout {
			public class Abstract : qx.core.Object {
			}
			public class VBox : Abstract {
				public string separator;

				public VBox (int spacing = 0, string align_y = "top", string? separator = null);
			}
			public class HBox : Abstract {
				public string separator;

				public HBox (int spacing = 0, string align_y = "left", string? separator = null);
			}
		}
	}
	namespace application {
		public class AbstractGUI : qx.core.Object {
			public ui.core.Widget root { get; }
		}

		public class Standalone : AbstractGUI {
		}
	}
}
