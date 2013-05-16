module templ.util;

import
  std.range,
  std.algorithm;

ptrdiff_t countUntilAny(Char1, Char2)(const(Char1)[] s, const(Char2)[][] subs) {
	auto indexes_of = map!((a) { return s.countUntil(a); })(subs);
	ptrdiff_t min_index = -1;
	foreach(index_of; indexes_of) {
		if(index_of != -1) {
			if(min_index == -1) {
				min_index = index_of;
			} else {
				min_index = min(min_index, index_of);
			}
		}
	}

	return min_index;
}

unittest {
	enum a = "1, 2, 3, 4";
	static assert(a.countUntilAny(["1", "2"]) == 0);
	static assert(a.countUntilAny(["2", "1"]) == 0);
	static assert(a.countUntilAny(["4", "2"]) == 3);
}
unittest {
	enum a = "1, 2, 3, 4";
	static assert(a.countUntilAny(["5", "1"]) == 0);
	static assert(a.countUntilAny(["5", "6"]) == -1);
}
