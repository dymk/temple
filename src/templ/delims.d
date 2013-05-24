module templ.delims;
import
	std.traits,
	std.typecons;

//A delimer and the index that its at
alias Tuple!(ptrdiff_t, "pos", Delim, "delim") DelimPos;

enum Delim {
	OpenShort,
	OpenShortStr,
	Open,
	OpenStr,
	CloseShort,
	Close
}
enum Delims = [EnumMembers!Delim];

enum OpenDelim  : Delim {
	OpenShort 		= Delim.OpenShort,
	Open 					= Delim.Open,
	OpenShortStr	= Delim.OpenShortStr,
	OpenStr 			= Delim.OpenStr
};
enum OpenDelims = [EnumMembers!OpenDelim];

enum CloseDelim : Delim {
	CloseShort 		= Delim.CloseShort,
	Close 				= Delim.Close
}
enum CloseDelims = [EnumMembers!CloseDelim];

enum OpenToClose = [
	OpenDelim.OpenShort    : CloseDelim.CloseShort,
	OpenDelim.OpenShortStr : CloseDelim.CloseShort,
	OpenDelim.Open         : CloseDelim.Close,
	OpenDelim.OpenStr      : CloseDelim.Close
];
unittest {
	static assert(OpenToClose[OpenDelim.Open] == CloseDelim.Close);
}

string toString(const Delim d) {
	with(Delim) {
		final switch(d) {
			case OpenShort: 		return "%";
			case OpenShortStr: 	return "%=";
			case Open: 					return "<%";
			case OpenStr: 			return "<%=";
			case CloseShort:		return "\n";
			case Close:					return "%>";
		}
	}
}
