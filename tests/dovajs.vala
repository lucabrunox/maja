using Javascript;

public class BrowserTest {
	public static bool onload () {
		var b = new MarkupBuilder (document);
		var body = document.get_elements_by_tag_name ("body")[0];
		body.append_child (b.div ([b.h1 ([b.text ("Test successful")]),
								   b.button (null, {"value": "Press me"}, {"onclick": ()=>{alert("Test successful"); return false;}})]));
		return false;
	}

	public static void main () {
		window.onload = onload;
	}
}
