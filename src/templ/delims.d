module templ.delims;
import
	std.traits,
	std.typecons;

//A delimer and the index that its at
template DelimPos(D = Delim) {
	alias DelimPos = Tuple!(ptrdiff_t, "pos", D, "delim");
}

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
	final switch(d) with(Delim) {
		case OpenShort: 		return "%";
		case OpenShortStr: 	return "%=";
		case Open: 					return "<%";
		case OpenStr: 			return "<%=";
		case CloseShort:		return "\n";
		case Close:					return "%>";
	}
}

bool isShort(const Delim d) {
	switch(d) with(Delim) {
		case OpenShortStr:
		case OpenShort   : return true;
		default          : return false;
	}
}

unittest {
	static assert(Delim.OpenShort.isShort() == true);
	static assert(Delim.Close.isShort() == false);
}

bool isStr(const Delim d) {
	switch(d) with(Delim) {
		case OpenShortStr:
		case OpenStr     : return true;
		default          : return false;
	}
}

unittest {
	static assert(Delim.OpenShort.isStr() == false);
	static assert(Delim.OpenShortStr.isStr() == true);
}
