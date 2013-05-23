module templ.delims;
import
	std.traits,
	std.typecons;

alias string Delim;

//A delimer and the index that its at
alias Tuple!(ptrdiff_t, "pos", Delim, "delim") DelimPos;

enum OpenDelim : Delim {
	//OpenShort    = "%",
	//OpenShortStr = "%=",
	Open         = "<%",
	OpenStr      = "<%="
}

enum CloseDelim : Delim {
	//CloseShort   = "\n",
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
	//OpenDelim.OpenShort    : CloseDelim.CloseShort,
	//OpenDelim.OpenShortStr : CloseDelim.CloseShort,
	OpenDelim.Open         : CloseDelim.Close,
	OpenDelim.OpenStr      : CloseDelim.Close
];
unittest {
	static assert(OpenClosePairs[OpenDelim.Open] == CloseDelim.Close);
	//static assert(OpenClosePairs[OpenDelim.OpenShortStr] == CloseDelim.CloseShort);
}
