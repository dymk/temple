module templ.token;

import
  std.string,
  std.array;

import
  templ.delims,
  templ.util;


struct Token {
	enum TokenType {
		Delim,
		StrLit
	}

	Delim delim() @property {
		if(tokenType != TokenType.Delim) {
			throw new Exception("Not a Delim type token");
		}
		return cast(Delim) _delim;
	}

	string str() @property {
		if(tokenType != TokenType.StrLit) {
			throw new Exception("Not a StrLit type token");
		}
		return cast(string) _str;
	}

private:
	TokenType _tokenType;

	union {
		Delim _delim;
		string _str;
	}
}

/**
 * Tokenize the template string
 *
 */
Token[] tokenize(const(char)[] templ_string) {
	Token[] tokens = [];
	while(!templ_string.empty) {
		immutable dPos = templ_string.nextDelim(Delims);
		if(dPos.pos == -1)
		{
			// No delim found, append rest of templ_string as a
			// string literal token
			tokens ~= Token(TokenType.StrLit, templ_string);
			templ_string = "";
		}
		else if(dPos.pos == 0)
		{
			immutable delim = dPos.delim;
			tokens ~= Token(TokenType.Delim, delim);
			templ_string = templ_string[delim.length .. $];
		}
		else
		{
			// Cut off string up to the delimer,
			// get the delmer and friends next time
			auto pos = dPos.pos;
			tokens ~= Token(TokenType.StrLit, templ_string[0..pos]);
			templ_string = templ_string[0..pos];
		}
	}
	return tokens;
}

version(unittest) {
	const foo_lit_tok = Token(TokenType.StrLit, "foo");
	const open_delim_tok = Token(TokenType.Delim, "<%");
}
unittest {
	assert(tokenize("foo") == [foo_lit_tok]);
}
