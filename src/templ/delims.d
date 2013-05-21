module templ.delims;
import
	std.traits,
	std.typecons;

alias string Delim;

//A delimer and the index that its at
template DelimPos(D : Delim) {
	alias Tuple!(long, "pos", D, "Delim") DelimPos;
}

enum OpenDelim : Delim {
	OpenShort    = "%",
	OpenShortStr = "%=",
	Open         = "<%",
	OpenStr      = "<%="
}

enum CloseDelim : Delim {
	CloseShort   = "\n",
	Close        = "%>"
}

// DMD doesn't like enums inhering from others
// or something; either way this is the best I
// can do for now.
enum OpenDelims  = cast(string[]) [EnumMembers!OpenDelim];
enum CloseDelims = cast(string[]) [EnumMembers!CloseDelim];
enum Delims      = OpenDelims ~ cast(Delim[])CloseDelims;

// TODO: DMD 2.062 can't do this
// But 2.063 beta can. So use that,
// until I figure out the version
// flags that 2.062 sets vs 063.
enum OpenClosePairs = [
	OpenDelim.OpenShort    : CloseDelim.CloseShort,
	OpenDelim.OpenShortStr : CloseDelim.CloseShort,
	OpenDelim.Open         : CloseDelim.Close,
	OpenDelim.OpenStr      : CloseDelim.Close
];
unittest {
	static assert(OpenClosePairs[OpenDelim.Open] == CloseDelim.Close);
	static assert(OpenClosePairs[OpenDelim.OpenShortStr] == CloseDelim.CloseShort);
}

//// For now use a final switch in place of a map.
//CloseDelim closeForOpen(OpenDelim open) {
//	// TODO: Another bug in DMD
//	// http://d.puremagic.com/issues/show_bug.cgi?id=10113
//	// Would use final switch, but that seems to
//	// not play nice with enum : string
//	// In fact 'final' does nothing here,
//	// yet produces no warnings.
//	final switch(cast(string)open) {
//		case OpenDelim.OpenShort:    return CloseDelim.CloseShort;
//		case OpenDelim.OpenShortStr: return CloseDelim.CloseShort;
//		case OpenDelim.Open:         return CloseDelim.Close;
//		case OpenDelim.OpenStr:      return CloseDelim.Close;
//	}
//	// So I guess this should provide marginal
//	// protection while that's worked out
//	throw new Exception("Unrecognized delimer: " ~ cast(string)open);
//}
