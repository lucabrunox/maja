void main () {
	var a = new ArrayList<string> ();
	a.append ("foo");
	assert (a[0] == "foo");
	a[0] = "bar";
	assert (a[0] == "bar");
}
