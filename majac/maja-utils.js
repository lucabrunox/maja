Maja = {}
Maja.bind = function (scope, func) {
    return function () {
	return func.apply (scope, arguments);
    }
};
Maja.inherit = function (subclass, superclass) {
    var helper = new Function;
    helper.prototype = superclass.prototype;
    subclass.prototype = new helper;
    subclass.prototype.constructor = subclass;
};
Maja.mixin = function (dest, over) {
    for (var key in over)
	dest[key] = over;
    return dest;
};
Maja.array = function (sizes) {
    // FIXME: more sizes
    var res = [];
    res[sizes[0]] = undefined;
    return res;
};
Maja.array_iterator = function (array) {
    return new Maja.ArrayIterator (array);
};
Maja.to_string = function () {
    if (typeof this == "string")
	return this;
    return this.to_string ();
};
Maja.get_keys = function (obj) {
    var res = [];
    for (var k in obj) {
	res.push (k);
    }
    return res;
};
Maja.get_values = function (obj) {
    var res = [];
    for (var k in obj) {
	res.push (obj[k]);
    }
    return res;
};
Maja.ArrayIterator = function (array) {
    this.array = array;
    this.index = -1;
};
Maja.ArrayIterator.prototype.next = function () {
    var length = this.array.length;
    if (this.index < length) {
	this.index++;
    }
    return this.index < length;
};
Maja.ArrayIterator.prototype.get = function () {
    return this.array[this.index];
};
