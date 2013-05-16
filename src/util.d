import
  std.range,
  std.algorithm;

uint leftIndexOfAny(Char1, Char2)(const(Char1)[] s, const(Char2)[][] subs) {
	auto indexes_of = map!((a) { return s.countUntil(a); })(subs);
	auto min_index = -1U;
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
	auto a = "1, 2, 3, 4";
	assert(a.leftIndexOfAny(["1", "2"]) == 0);
	assert(a.leftIndexOfAny(["4", "2"]) == 3);
	assert(a.leftIndexOfAny(["5", "1"]) == 0);
	assert(a.leftIndexOfAny(["5", "6"]) == -1);
}
