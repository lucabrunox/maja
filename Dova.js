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
