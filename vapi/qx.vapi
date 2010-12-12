[Javascript (camelcase = true, no_maja_init = true)]
namespace qx {
	namespace util {
		public class ColorUtil {
			public static int[] css_string_to_rgb (string str);
		}
	}
	namespace fx {
		public class Base : core.Object {
			public void start ();
		}
		namespace queue {
			public class Queue {
				public int limit;
			}
			public class Manager {
				public Queue default_queue { get; }
				public static Manager instance { get; }
			}
		}
		namespace effect {
			namespace core {
				public class Fade : fx.Base {
					public Fade (Javascript.DOM.Element element);
				}
				public class Scroll : fx.Base {
					public Scroll (Javascript.DOM.Element element);
				}
				public class Scale : fx.Base {
					public Scale (Javascript.DOM.Element element);
				}
				public class Move : fx.Base {
					public Move (Javascript.DOM.Element element);
				}
				public class Highlight : fx.Base {
					public Highlight (Javascript.DOM.Element element);
				}
			}
			namespace combination {
				public class Shake : fx.Base {
					public Shake (Javascript.DOM.Element element);
				}
				public class Shrink : fx.Base {
					public Shrink (Javascript.DOM.Element element);
				}
				public class Grow : fx.Base {
					public Grow (Javascript.DOM.Element element);
				}
				public class ColorFlow : fx.Base {
					public ColorFlow (Javascript.DOM.Element element);
				}
				public class Pulsate : fx.Base {
					public Pulsate (Javascript.DOM.Element element);
				}
				public class Puff : fx.Base {
					public bool modify_display;
					public Puff (Javascript.DOM.Element element);
				}
				public class Drop : fx.Base {
					public string mode;
					public Drop (Javascript.DOM.Element element);
				}
				public class Fold : fx.Base {
					public string mode;
					public Fold (Javascript.DOM.Element element);
				}
				public class Switch : fx.Base {
					public bool modify_display;
					public Switch (Javascript.DOM.Element element);
				}
			}
		}
	}
	namespace lang {
		public delegate any JsonTransformer (string key, any value);
		public class Json {
			public static Javascript.Object parse (string text, JsonTransformer? reviver = null);
		}
		public class Function {
			public static void delay (Javascript.Callback func, int delay);
		}
	}
	namespace io {
		namespace remote {
			public class Request : core.Object {
				public int timeout;
				public bool prohibit_caching;
				public Request (string url, string method = "GET", string response_type = "text/plain");
				public void send ();
			}
		}
	}
	namespace bom {
		namespace element {
			public class Style {
				public static T get<T> (Javascript.DOM.Element element, string key);
			}
			public class Dimension {
				public static double get_width (Javascript.DOM.Element element);
			}
			public class Location {
				public static double get_left (Javascript.DOM.Element element);
			}
		}
		namespace client {
			public class Engine {
				public static const bool MSHTML;
			}
		}
		public class History : qx.core.Object {
			public static History get_instance ();
			public string state;
			public void add_to_history (string state, string? new_title = null);
		}
	}
	namespace log {
		public class Logger {
			public static void unregister (any appender);
			public static void debug (string message);
		}
		namespace appender {
			public class Element : qx.core.Object {
				[Javascript (name = "\$\$id", simple_field = true)]
				public any id { get; set; }
				public Javascript.DOM.Element element { set; }
				public Element (Javascript.DOM.Element? element = null);
				public void clear ();
			}
		}
	}
	namespace html {
		public class Element : qx.core.Object {
			public Javascript.DOM.Element dom_element { get; } 
			public void set_attribute (string key, string value, bool direct = false);
			public void use_element (Javascript.DOM.Element element);
		}
	}
	namespace event {
		namespace type {
			public class Event {
				public string type;
			}
		}
		public delegate void Callback (dynamic type.Event? e);
		public class Timer : core.Object {
			public Timer (int interval);
			public static Timer once ([Javascript (has_this_parameter = true)] Callback function, int timeout);
			public void start ();
		}
	}
	namespace core {
		public class Setting {
			public static T get<T> (string key);
		}
		public class Object {
			public string tr (string str);
			public void error (...);
			public void debug (...);
			public string add_listener (string type, [Javascript (has_this_parameter = true)] qx.event.Callback listener, bool capture = false);
			public string add_listener_once (string type, [Javascript (has_this_parameter = true)] qx.event.Callback listener, bool capture = false);
			[Javascript (setter = false)]
			public T set<T> (string key, T value);
			[Javascript (name = "set")]
			public Object set_many (Dova.Map<string,any> data);
			public void set_user_data<T> (string key, T value);
			public T get_user_data<T> (string key);
		}
		public class Variant {
			public static bool is_set (string key, string variants);
		}
	}
	namespace ui {
		namespace groupbox {
			public class GroupBox : core.Widget {
				public layout.Abstract layout;
				public GroupBox (string legend = "", string icon = "");
				public void add (core.LayoutItem child, Dova.Map<string,any>? options = null);
			}
		}
		namespace decoration {
			public class Abstract : qx.core.Object {
			}
			public class Background : Abstract {
				public Background (string? color = null);
			}
		}
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
				public Dova.List<AbstractTreeItem> children { get; }

				public Tree ();

				public AbstractTreeItem get_next_node_of (AbstractTreeItem tree_item, bool invisible = true);
				public AbstractTreeItem get_previous_node_of (AbstractTreeItem tree_item, bool invisible = true);
				public Dova.List<AbstractTreeItem> get_items (bool recursive = false, bool invisible = true);
			}
			public class AbstractTreeItem : core.Widget {
				public Tree? tree { get; }
				public Dova.List<AbstractTreeItem> children { get; }
				public string label;
				public bool open;
				public AbstractTreeItem parent;
				public void add (...);
				public Dova.List<AbstractTreeItem> get_items (bool recursive = true, bool invisible = true, bool ignore_first = true);
			}
			public class TreeFolder : AbstractTreeItem {
				public TreeFolder (string? label = null);
			}
			public class TreeFile : AbstractTreeItem {
				public TreeFile (string? label = null);
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
			public class Html : core.Widget {
				public Html (string? html = null);
				public void set_overflow (string overflow_x, string overflow_y);
			}
			public class AbstractIframe : core.Widget {
				public dynamic Javascript.Window window { get; }
				public string source;
				public void reload ();
			}
			public class Iframe : AbstractIframe {
				public Iframe ();
			}
		}
		namespace basic {
			public class Atom : core.Widget {
			}
			public class Label : core.Widget {
				public string text_align;
				public string value;
				public bool rich;

				public Label (string value);
			}
			public class Image : core.Widget {
				public Image (string? source = null);
			}
		}
		namespace container {
			public class Stack : core.Widget {
				public Dova.List<core.Widget> selection;
				public Stack ();
				public void add (core.Widget widget);
				public void reset_selection ();
			}
			public class Composite : core.Widget {
				public layout.Abstract layout;

				public Composite (layout.Abstract? layout = null);
				public void add (core.LayoutItem child, Dova.Map<string,any>? options = null);
			}
		}
		namespace form {
			public class TextArea : form.AbstractField {
				public TextArea (string value = "");
			}
			public class Button : basic.Atom {
				public string label;
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
			public class PasswordField : TextField {
				public PasswordField (string? value = null);
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
				public class Bounds {
					[Javascript (simple_field = true)]
					public double width { get; set; }
					[Javascript (simple_field = true)]
					public double height { get; set; }
					[Javascript (simple_field = true)]
					public double left { get; set; }
					[Javascript (simple_field = true)]
					public double top { get; set; }
				}
				public int min_width;
				public int width;
				public int margin;
				public bool allow_grow_x;
				public bool allow_stretch_x;
				public Bounds bounds;
			}
			public class Widget : LayoutItem {
				public string font;
				public string appearance;
				public string visibility;
				public string tool_tip_text;
				[Javascript (name = "decorator")]
				public string decorator_name { get; set; }
				public decoration.Abstract decorator;
				public string background_color;
				public bool enabled;
				public html.Element content_element { get; }
				public html.Element container_element { get; }
				public int z_index;

				public bool is_visible ();
				public void exclude ();
				public void show ();
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
				public string align_x;

				public VBox (int spacing = 0, string align_y = "top", string? separator = null);
			}
			public class HBox : Abstract {
				public string separator;

				public HBox (int spacing = 0, string align_y = "left", string? separator = null);
			}
			public class Grid : Abstract {
				public Grid (int spacing_x = 0, int spacing_y = 0);
				public void set_column_align (int column, string h_align, string v_align);
				public void set_row_align (int row, string h_align, string v_align);
				public void set_column_width (int column, int width);
				public void set_row_height (int row, int height);
			}
			public class Grow : Abstract {
				public class Grow ();
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
