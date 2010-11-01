Dova = {}
Dova.bind = function(scope, func) {
    return function() {
	return func.apply(scope, arguments);
    }
};
Dova.mixin = function(dest, over) {
    for (var key in over)
	dest[key] = over;
    return dest;
};
Dova.array = function(sizes) {
    // FIXME: more sizes
    var res = [];
    res[sizes[0]] = undefined;
};
Dova.to_string = function() {
    if (typeof this == "string")
	return this;
    return this.to_string ();
};
