module temple.util;

import
  std.algorithm,
  std.typecons,
  std.array,
  std.uni;

import temple.delims;

bool validBeforeShort(string str) {
	// Check that the tail of str is whitespace
	// before a newline, or nothing.
	foreach_reverse(dchar chr; str) {
		if(chr == '\n') { return true; }
		if(!chr.isWhite()) { return false; }
	}
	return true;
}

unittest {
	static assert("   ".validBeforeShort() == true);
	static assert(" \t".validBeforeShort() == true);
	static assert("foo\n".validBeforeShort() == true);
	static assert("foo\n  ".validBeforeShort() == true);
	static assert("foo\n  \t".validBeforeShort() == true);

	static assert("foo  \t".validBeforeShort() == false);
	static assert("foo".validBeforeShort() == false);
	static assert("\nfoo".validBeforeShort() == false);
}

void munchHeadOf(ref string a, ref string b, size_t amt) {
	// Transfers amt of b's head onto a's tail
	a = a ~ b[0..amt];
	b = b[amt..$];
}

unittest {
	auto a = "123";
	auto b = "abc";
	a.munchHeadOf(b, 1);
	assert(a == "123a");
	assert(b == "bc");
}
unittest {
	auto a = "123";
	auto b = "abc";
	a.munchHeadOf(b, b.length);
	assert(a == "123abc");
	assert(b == "");
}

DelimPos!D* nextDelim(Char1 : char, D)(const(Char1)[] haystack, const D[] delims) {

	alias Tuple!(Delim, "delim", string, "str") DelimStrPair;

	//auto delims_strs =      delims.map!(a => new DelimStrPair(a, a.toString()) )().array();
	//auto delim_strs  = delims_strs.map!(a => a.str)().array();
	DelimStrPair[] delims_strs;
	foreach(delim; delims) {
		delims_strs ~= DelimStrPair(delim, toString(delim));
	}

	string[] delim_strs;
	foreach(delim; delims) {
		// Would use ~= here, but CTFE in 2.063 can't handle it
		delim_strs = delim_strs ~ toString(delim);
	}

	auto atPos = countUntilAny(haystack, delim_strs);
	if(atPos == -1) {
		return null;
	}

	auto sorted = delims_strs.sort!("a.str.length > b.str.length")();
	foreach(ref s; sorted) {
		if(startsWith(haystack[atPos..$], s.str)) {
			return new DelimPos!D(atPos, cast(D)s.delim);
		}
	}
	throw new Exception("Impossible");
}

unittest {
	const haystack = Delim.Open.toString();
	static assert(*(haystack.nextDelim([Delim.Open])) == DelimPos!Delim(0, Delim.Open));
}
unittest {
	const haystack = "foo";
	static assert(haystack.nextDelim([Delim.Open]) is null);
}

ptrdiff_t countUntilAny(Char1, StrArr)(const(Char1)[] s, StrArr subs) {
	auto indexes_of = subs.map!((a) { return s.countUntil(cast(string)a); })();
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
unittest {
	enum a = "%>";
	static assert(a.countUntilAny(["<%", "<%="]) == -1);
}

string escapeQuotes(string unclean) {
	unclean = unclean.replace(`"`, `\"`);
	unclean = unclean.replace(`'`, `\'`);
	return unclean;
}
unittest {
	static assert(escapeQuotes(`"`) == `\"`);
	static assert(escapeQuotes(`'`) == `\'`);
}

string stripWs(string unclean) {
	return unclean.filter!(
		(a) { return !isWhite(a); } //Filter any WS
	)().map!(
		(a) { return cast(char) a; } //cast back to char
	)().array().idup;
}
unittest {
	static assert(stripWs("") == "");
	static assert(stripWs("    \t") == "");
	static assert(stripWs(" a s d f ") == "asdf");
	static assert(stripWs(" a\ns\rd f ") == "asdf");
}
