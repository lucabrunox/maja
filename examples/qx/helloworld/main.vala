using Javascript;
using qx.ui;

public void vala_qx_main (qx.application.Standalone app) {
	// Create a button
	var button1 = new form.Button ("First Button", "test/test.png");

	// Document is the application root
	var doc = (container.Composite) app.root;

	// Add button to document at fixed coordinates
	doc.add(button1, {"left": 100, "top": 50});

	// Add an event listener
	button1.add_listener("execute", (e) => {
			alert("Hello World!");
		});
}
