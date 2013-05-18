module templ.templ;
import templ.util;
import 
  std.array,
  std.algorithm,
  std.typecons;

string gen_templ_func_string(Context)(string templ) {
	enum OPEN_DELIM_SHORT = "%";
	enum OPEN_DELIM_SHORT_STR = "%=";
	enum OPEN_DELIM = "<%";
	enum OPEN_DELIM_STR = "<%=";
	enum CLOSE_DELIM_SHORT = "\n";
	enum CLOSE_DELIM = "%>";

	alias Tuple!(typeof(OPEN_DELIM), typeof(CLOSE_DELIM)) DelimPair;

	enum DELIM_PAIRS = [
		DelimPair(OPEN_DELIM_SHORT, CLOSE_DELIM_SHORT),
		DelimPair(OPEN_DELIM_SHORT_STR, CLOSE_DELIM_SHORT),
		DelimPair(OPEN_DELIM, CLOSE_DELIM),
		DelimPair(OPEN_DELIM_STR, CLOSE_DELIM),
	];

	enum OPEN_DELIMS  = DELIM_PAIRS.map!(dp => dp[0])().array().uniq();
	enum CLOSE_DELIMS = DELIM_PAIRS.map!(dp => dp[1])().array().uniq();

	auto function_body = "";
	auto indent_level = 0;

	void push_line(string[] stmts...) {
		foreach(i; 0..indent_level) {
			function_body ~= '\t';
		}
		foreach(stmt; stmts) {
			function_body ~= stmt;
		}
		function_body ~= '\n';
	}

	void indent() { indent_level++; }
	void outdent() { indent_level--; }

	//generates something like
	/+
	(Ctx __context) {
		alias __context.a a;
		auto d_code = "";
		//generated code
		return d_code;
	}+/

	enum context_given = !is(Context == void);
	static if(!context_given) {
		push_line("() {");
	} else {
		enum ContextType = __traits(identifier, Context);
		push_line("(", ContextType, " __context) {");
	}
	indent();
	push_line("import std.conv;");
	push_line("import std.array;");
	push_line("auto __buff = appender!string();");

	//generate local bindings to context fields
	if(context_given) {
		push_line("with(__context) {");
		indent();
	}

	while(!templ.empty) {
		// open delimer position
		immutable odpos = templ.countUntilAny([
			OPEN_DELIM_SHORT_STR,
			OPEN_DELIM_SHORT, 
			OPEN_DELIM_STR,
			OPEN_DELIM
		]);

		if(odpos != -1) {
			if(templ[0..odpos].length) {
				//Append everything before the open delimer to the buffer
				push_line(`__buff.put("` ~ templ[0..odpos].escapeQuotes() ~ `");`);
			}

			//discard anything before open delim
			templ = templ[odpos..$]

			immutable string odelim;
			if(templ.startsWith(OPEN_DELIM_SHORT_STR)) {
				odelim = OPEN_DELIM_SHORT_STR;
			} else if(templ.startsWith(OPEN_DELIM_SHORT)) {
				odelim = OPEN_DELIM_SHORT;
			} else if(templ.startsWith(OPEN_DELIM_STR)) {
				odelim = OPEN_DELIM_STR;
			} else if

			//check for shorthand delims and find next newline
			if(
				templ.startsWith(OPEN_DELIM_SHORT) ||
				templ.startsWith(OPEN_DELIM_SHORT_STR)
			) {
				auto close = templ.countUntil('\n');
				if(close == -1) {
					close = templ.length - 1;
				}
				auto inbetween_delims = templ[OPEN_DELIM_SHORT.length .. close];
				push_line(inbetween_delims);

			}

			//find the next close delimer
			auto close = templ[odpos..$].countUntil(CLOSE_DELIM);
			assert(close != -1, "Missing close delimer '" ~ CLOSE_DELIM ~ "'. (" ~ templ ~ ")");
			close += odpos; //add index position lost by slicing from 0..odpos

			string delim_type;
			if(templ[odpos..odpos+OPEN_DELIM_STR.length] == OPEN_DELIM_STR) {
				delim_type = OPEN_DELIM_STR;
			} else if(templ[odpos..odpos+OPEN_DELIM.length] == OPEN_DELIM) {
				delim_type = OPEN_DELIM;
			} else {
				assert(false, "Unknown delimer at " ~ templ[odpos..odpos+5]);
			}

			auto inbetween_delims = templ[odpos+delim_type.length ..close];

			if(delim_type == OPEN_DELIM_STR) {
				//Was an evaluate + output string delimer
				push_line(`__buff.put(to!string((` ~ inbetween_delims ~ `)));`);
			} else {
				//Was an evaluate delimer
				push_line(inbetween_delims);
			}

			templ = templ[close + CLOSE_DELIM.length .. $];
		}
		else {
			//no more odpos delimers, append rest to buffer
			push_line(`__buff.put("` ~ templ[0..$].escapeQuotes() ~ `");`);
			break;
		}
	}

	if(context_given) {
		outdent();
		push_line("}");
	}

	push_line("return __buff.data();");
	outdent();
	push_line("}");

	return function_body;
}

/**
* Call like 
* 
* ----
* mixin Templ!(Context, string templ_string)
* ----
* or
* ----
* Templ!(string templ_string)
* ----
* where Context is an arbitrary context type 
*/

template Templ(string template_string) {
	enum Templ = mixin(gen_templ_func_string!void(template_string));
}

template Templ(Context, string template_string) {
	enum Templ = gen_templ_func_string!Context(template_string);
}

version(unittest) {
	import std.string;
}
unittest {
	//Test delimer parsing
	const render = Templ!("<% if(true) { %>foo<% } %>");
	static assert(render() == "foo");
}
unittest {
	//Test to!string of eval delimers
	const render = Templ!(`<%= "foo" %>`);
	static assert(render() == "foo");
}
unittest {
	//Test raw text with no delimers
	const render = Templ!(`foo`);
	static assert(render() == "foo");
}
unittest {
	//Assert that it's invalid if no context is used
	static assert(!__traits(compiles, Templ!(`<%= test %>`)));
}
unittest {
	//Assert that it's invalid if invalid context fields are used
	struct Ctx {
		string foo;
	}
	static assert(!__traits(compiles, Templ!(`<%= bar %>`)));
}
unittest {
	//Test static context fields
	struct Ctx {
		static static_field = "static value";
	}
	const render = mixin(Templ!(Ctx, `<%= static_field %>`));
	assert(render(Ctx()) == "static value");
}
unittest {
	//Test member context fields
	struct Ctx {
		auto member_field = "member value";
	}
	const render = mixin(Templ!(Ctx, `<%= member_field %>`));
	static assert(render(Ctx()) == "member value");
}
unittest {
	//Test looping
	const templ = `<% foreach(i; 0..3) { %>foo<% } %>`;
	const render = Templ!templ;
	static assert(render() == "foofoofoo");
}
unittest {
	//Test looping
	const templ = `<% foreach(i; 0..3) { %><%= i %><% } %>`;
	const render = Templ!templ;
	static assert(render() == "012");
}
unittest {
	//Test method calling & context state on contexts
	struct Ctx {
		int foo() {
			return n_foo++;
		}
		int n_foo;
	}
	const templ = `<% foreach(i; 0..3) { %><%= foo() %><% } %>`;
	const render = mixin(Templ!(Ctx, templ));
	static assert(render(Ctx()) == "012");
}
unittest {
	//Test escaping of "
	const templ = `"`;
	const render = Templ!templ;
	static assert(render() == `"`);
}
unittest {
	//Test escaping of '
	const templ = `'`;
	const render = Templ!templ;
	static assert(render() == `'`);
}
unittest {
	//Test unmatched closing delimer
	const templ = `%>`;
	const render = Templ!templ;
	static assert(render() == `%>`);
}
unittest {
	//Test <% %> shorthand %
	const templ = q{
		% foreach(i; 0..3) {
			<%= i %>
		% }
	}.outdent();
	//const render = Templ!templ;
	const render = gen_templ_func_string!void(templ);
	pragma(msg, render);
	//static assert(render().stripWs == `012`);
}
