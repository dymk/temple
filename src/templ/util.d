module templ.util;

import
  std.range,
  std.array,
  std.string,
  std.uni,
  std.typecons,
  std.traits,
  std.algorithm;

import templ.delims;

auto CTFEMap(alias)

// TODO: have nextDelim return a Maybe type
// instead of a DelimPos with pos=-1
DelimPos nextDelim(Char1 : char)(const(Char1)[] haystack, const Delim[] delims) {

	alias Tuple!(Delim, "delim", string, "str") DelimStrPair;

	auto delims_strs = delims.map!( a => DelimStrPair(a, a.toString()) )().CTFEArray();
	auto delim_strs = delims_strs.map!(a => a.str)().CTFEArray();

	auto atPos = countUntilAny(haystack, delim_strs);
	if(atPos == -1) {
		return DelimPos(-1, cast(Delim)0);
	}

	auto sorted = delims_strs.sort!("a.str.length > b.str.length")();
	foreach(ref s; sorted) {
		if(startsWith(haystack[atPos..$], s.str)) {
			return DelimPos(atPos, s.delim);
		}
	}
	throw new Exception("Shouln't ever get here");
}

unittest {
	const d = Delim.Open.toString();
	static assert(d.nextDelim([Delim.Open]) == DelimPos(0, Delim.Open));
	static assert("foo".nextDelim([Delim.Open]) == DelimPos(-1, Delim.Open));
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
unittest {
	// TODO: Get Delims[] to cast to string[] automatically
	enum a = "<%";
	static assert(a.countUntilAny(cast(string[])OpenDelims) == 0);
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

//Returns the deimer that the string starts with
D frontDelim(D : const(string))(string str, D[] delims) {
	//Sort so longer delims are compared first
	//Eg, <%= is checked before <%
	delims.sort!((a, b) {
		return a.length > b.length;
	})();

	foreach(delim; delims) {
		if(str.startsWith(cast(string)delim)) {
			return delim;
		}
	}
	return null;
}

unittest {
	enum DELIMS = [
		"<%",
		"<%=",
		"aa",
		"a"
	];

	static assert("a".frontDelim(DELIMS) == "a");
	static assert("aa".frontDelim(DELIMS) == "aa");
	static assert("<%".frontDelim(DELIMS) == "<%");
	static assert("<%=".frontDelim(DELIMS) == "<%=");
	static assert("%".frontDelim(DELIMS) == null);
}
