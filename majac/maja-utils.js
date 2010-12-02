Maja = {}
Maja.bind = function(scope, func) {
    return function() {
	return func.apply(scope, arguments);
    }
};
Maja.mixin = function(dest, over) {
    for (var key in over)
	dest[key] = over;
    return dest;
};
Maja.array = function(sizes) {
    // FIXME: more sizes
    var res = [];
    res[sizes[0]] = undefined;
    return res;
};
Maja.to_string = function() {
    if (typeof this == "string")
	return this;
    return this.to_string ();
};
