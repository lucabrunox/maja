void test_string () {
	assert ("foo".to_upper () == "FOO");
	assert ("foo" + "bar" == "foobar");
	assert (",".join (["foo", "bar"]) == "foo,bar");
}

void test_map () {
	var map = {"foo": "bar", "oof": "rab"};
	var keys = map.keys;
	assert ("foo" in keys);
	assert ("oof" in keys);
	var values = map.values;
	assert ("bar" in values);
	assert ("rab" in values);
}

void main () {
	test_string ();
	test_map ();
}
