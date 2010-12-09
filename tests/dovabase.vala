void test_string () {
	assert ("foo".to_upper () == "FOO");
	assert ("foo" + "bar" == "foobar");
	assert (",".join (["foo", "bar"]) == "foo,bar");
}

void main () {
	test_string ();
}