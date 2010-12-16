using Javascript;

public class BrowserTest {
	public static bool onload () {
		var b = new HTMLBuilder (document);
		var body = document.get_elements_by_tag_name ("body")[0];
		var table = b.table ([b.tr ([b.th ("Labels"), b.th ("Fields")]),
							  b.tbody ([b.tr ([b.td ([b.em("Text field: ")]),
											   b.textfield (null, {"value": "initial text"})]),
										b.tr ([b.td ([b.strong("Text field: ")]),
											   b.passwordfield ()])
										   ])]);
		body.append_child (b.div ([b.h1 ("Test successful"),
								   b.hr (),
								   b.button (null, {"value": "Press me"}, {"onclick": ()=>{alert("Test successful"); return false;}}),
								   b.br (),
								   b.select ([b.option([b.text ("Option 1")], {"value": "option1"}),
											  b.option([b.text ("Option 2")], {"value": "option2"})]),
								   b.hr (),
								   b.form (null, [table])
									  ]));
		return false;
	}

	public static void main () {
		window.onload = onload;
	}
}
