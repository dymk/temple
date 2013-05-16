module templ.templ;
import templ.util;
import std.array;
import std.algorithm;

string gen_templ_func_string(Context)(string template_string) {
	enum OPEN_DELIM = "<%";
	enum OPEN_DELIM_STR = "<%=";
	enum CLOSE_DELIM = "%>";

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

	while(!template_string.empty) {
		auto open = template_string.countUntilAny([OPEN_DELIM, OPEN_DELIM_STR]);
		if(open != -1) {
			//pragma(msg, "Found open delimer @" ~ open ~ " in '" ~ template_string ~ "': " ~ template_string[open..$]);

			if(template_string[0..open].length) {
				//Append everything before the open delimer onto the string
				push_line(`__buff.put("` ~ template_string[0..open] ~ `");`);
			}

			//find the next close delimer
			auto close = template_string[open..$].countUntil(CLOSE_DELIM);
			assert(close != -1, "Missing close delimer '" ~ CLOSE_DELIM ~ "'. (" ~ template_string ~ ")");
			close += open; //add index position lost by slicing from 0..open

			string delim_type;
			if(template_string[open..open+OPEN_DELIM_STR.length] == OPEN_DELIM_STR) {
				delim_type = OPEN_DELIM_STR;
			} else if(template_string[open..open+OPEN_DELIM.length] == OPEN_DELIM) {
				delim_type = OPEN_DELIM;
			} else {
				assert(false, "Unknown delimer at " ~ template_string[open..open+5]);
			}

			auto inbetween_delims = template_string[open+delim_type.length ..close];

			if(delim_type == OPEN_DELIM_STR) {
				//Was an evaluate + output string delimer
				push_line(`__buff.put(to!string((` ~ inbetween_delims ~ `)));`);
			} else {
				//Was an evaluate delimer
				push_line(inbetween_delims);
			}

			template_string = template_string[close + CLOSE_DELIM.length .. $];
		}
		else {
			//no more open delimers, append rest to buffer
			push_line(`__buff.put("` ~ template_string[0..$] ~ `");`);
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
	assert(render(Ctx()) == "012");
}
