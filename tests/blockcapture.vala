public delegate int Bar ();

public class Foo {
	public Bar bar;

	public Foo (Bar bar) {
		this.bar = bar;
	}
}

void main () {
	var foos = new Foo[10];
	for (var i = 0; i < 10; i++) {
		var j = i;
		foos[i] = new Foo (() => { return j; });
	}
	for (var i = 0; i < 10; i++) {
		assert (foos[i].bar () == i);
	}
}
