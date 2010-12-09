void test_switch () {
	int x = 10;
	switch (x) {
	case 1:
		assert_not_reached ();
	case 10:
	case 11:
		x = 20;
		break;
	default:
		assert_not_reached ();
	}
	assert (x == 20);
}

public delegate int Bar ();

public void foo (Bar bar) {
}

void test_captured_loop () {
	int i;
	for (i = 0; i < 10; i++) {
		var j = i;
		foo (() => { i++; j++; return i; });
		break;
	}
	assert (i == 0);
}

public class Foo {
	public Bar bar;

	public Foo (Bar bar) {
		this.bar = bar;
	}
}

void test_block_capture () {
	var foos = new Foo[10];
	for (var i = 0; i < 10; i++) {
		var j = i;
		foos[i] = new Foo (() => { return j; });
	}
	for (var i = 0; i < 10; i++) {
		assert (foos[i].bar () == i);
	}
}

void main () {
	test_switch ();
	test_captured_loop ();
	test_block_capture ();
}