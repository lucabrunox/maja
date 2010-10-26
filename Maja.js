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
