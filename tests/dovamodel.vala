void test_array_list () {
	var a = new ArrayList<string> ();
	a.append ("foo");
	assert (a[0] == "foo");
	a[0] = "bar";
	assert (a[0] == "bar");
	a.append ("foo");
	var i = 0;
	foreach (var elem in a) {
		assert (a[i++] == elem);
	}
}

public class Foo {
	public override bool equals (any? other) {
		return true;
	}
}

void test_equals () {
	var foo1 = new Foo ();
	var foo2 = new Foo ();
	assert (foo1 != foo2);
	assert (foo1.equals (foo2));

	var s1 = "foo";
	var s2 = "foo";
	assert (s1 == s2);
	assert (((any)s1).equals (s2));
}

void main () {
	test_array_list ();
	test_equals ();
}
