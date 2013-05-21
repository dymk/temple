module templ.templ;
import
  templ.util,
  templ.delims;

import
  std.array,
  std.algorithm,
  std.conv,
  std.traits,
  std.exception,
  std.typecons;

string gen_templ_func_string(Context)(string templ) {

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

	// Generates something like
	/+
	(Ctx __context) {
		alias __context.a a;
		auto d_code = "";
		//generated code
		return d_code;
	}+/

	enum isContextGiven = !is(Context == void);
	static if(!isContextGiven) {
		push_line("() {");
	} else {
		enum ContextType = __traits(identifier, Context);
		push_line("(", ContextType, " __context) {");
	}
	indent();
	push_line(`import std.conv;`);
	push_line(`import std.array;`);
	push_line(`auto __buff = appender!string();`);
	push_line(`__buff.put("");`);

	//generate local bindings to context fields
	if(isContextGiven) {
		push_line("with(__context) {");
		indent();
	}

	// Sanity check because the compiler likes to
	// crash my poor laptop on an infinite loop.
	int overflow = 0;

	while(!templ.empty) {
		overflow++;
		if(overflow > 100) {
			throw new Exception(templ);
		}

		immutable openDeilmPos = templ.nextDelim(OpenDelims);
		immutable odPos = openDeilm.pos;
		immutable openDelim = openDelim.delim;

		//assert(false, templ ~ " " ~ to!string(odPos) ~ " " ~ to!string(cast(string[])OpenDelims));
		if(odPos == -1) {
			push_line(`__buff.put("` ~ templ.escapeQuotes() ~ `");`);
			templ = "";
		} else {
			immutable closeDelim = OpenClosePairs[openDelim];

			if(openDelim.isShort())

			if(odPos != 0) {
				//Append everything before the open delimer to the buffer
				push_line(`__buff.put("` ~ templ[0..odPos].escapeQuotes() ~ `");`);
				templ = templ[odPos..$];
			}

			// I have no idea why I have to concat it with "", but that fixes
			// the compiler crash
			// TODO: CTFE crashes on countUntil
			// when enum : string is casted to string
			immutable cdPos = templ.countUntil("" ~ cast(string)closeDelim);
			assert(cdPos != -1, "Couldn't find close delim '" ~ closeDelim ~ "'.");
			immutable inBetweenDelims = templ[openDelim.length .. cdPos];

			// Check that shorthand delims don't have any non-ws
			// before them on thier line.
			//switch(cast(string) openDelim) {
			//	case OpenDelim.OpenShortStr:
			//	case OpenDelim.OpenShort:
			//}

			switch(cast(string) openDelim) {
				case OpenDelim.OpenStr:
				case OpenDelim.OpenShortStr:
					push_line(`__buff.put(to!string((` ~ inBetweenDelims ~ `)));`);
					break;

				case OpenDelim.Open:
				case OpenDelim.OpenShort:
					push_line(inBetweenDelims);
					break;
				default:
					// Should never get here, but because
					// final switch is broken:
					assert(false, "Invalid delimer: " ~ openDelim);
			}

			//Cut off what was inserted in the function body
			templ = templ[cdPos + closeDelim.length .. $];
		}
	}

	if(isContextGiven) {
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
	import std.stdio;
}
unittest {
	const render = Templ!("");
	static assert(render() == "");
}
unittest {
	// Test delimer parsing
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
	//Test <% %> shorthand %
	const templ = q{
		% foreach(i; 0..3) {
			<%= i %>
		% }
	}.outdent();
	const render = Templ!templ;
	// TODO: Compiler complains it can't CTFE this,
	// even though the individual functions are
	// statically unit-testable just fine.
	assert(render().stripWs() == `012`);
}
unittest {
	// Test anything before shorthand
	// delim is either whitespace or
	// a newline.
	const templ = q{
		test %foo
	}.outdent();
	const render = Templ!templ;
	assert(render().stripWs == "test%foo");
}
