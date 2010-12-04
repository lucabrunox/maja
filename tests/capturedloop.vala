public delegate void Bar ();

public void foo (Bar bar) {
}

public static void main () {
	int i;
	for (i = 0; i < 10; i++) {
		var j = i;
		foo (() => { i++; j++; });
		break;
	}
	assert (i == 0);
}
