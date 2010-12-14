using Javascript;

public class BrowserTest {
	public static bool onload () {
		var b = new MarkupBuilder (document);
		document.get_elements_by_tag_name ("body")[0].append_child (b.h1 ([b.text ("Test successful")]));
		return false;
	}

	public static void main () {
		window.onload = onload;
	}
}
