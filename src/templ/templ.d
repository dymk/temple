module templ.templ;
import
  templ.util,
  templ.delims;

import
  std.array,
  std.exception;

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

	// Generates a function akin to
	/+
	(Ctx __context) {
		alias __context.a a;
		auto d_code = "";
		//generated code
		return d_code;
	}
	+/

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

	auto safeswitch = 0;

	string prevTempl = "";

	while(!templ.empty) {
		if(safeswitch++ > 100) {
			assert(false, "throwing saftey switch: " ~ templ);
		}

		DelimPos!OpenDelim* oDelimPos = templ.nextDelim(OpenDelims);

		if(oDelimPos is null)
		{
			//No more delims; append the rest as a string
			push_line(`__buff.put("` ~ templ.escapeQuotes() ~ `");`);
			prevTempl.munchHeadOf(templ, templ.length);
		}
		else
		{
			immutable OpenDelim  oDelim = oDelimPos.delim;
			immutable CloseDelim cDelim = OpenToClose[oDelim];

			if(oDelimPos.pos == 0)
			{
				// Delim is at the start of templ
				if(oDelim.isShort()) {
					if(!prevTempl.validBeforeShort()) {
						// Chars before % were invalid, assume it's part of a
						// string literal.
						push_line(`__buff.put("` ~ templ[0..oDelim.toString().length] ~ `");`);
						prevTempl.munchHeadOf(templ, oDelim.toString().length);
						continue;
					}
				}

				// If we made it this far, we've got valid open/close delims
				auto cDelimPos = templ.nextDelim([cDelim]);
				if(cDelimPos is null) {
					if(oDelim.isShort()) {
						// don't require a short close delim at the end of the template
						templ ~= cDelim.toString();
						cDelimPos = enforce(templ.nextDelim([cDelim]));
					} else {
						assert(false, "Missing close delimer: " ~ cDelim.toString());
					}
				}

				// Made it this far, we've got the position of the close delimer.
				auto inBetweenDelims = templ[oDelim.toString().length .. cDelimPos.pos];
				if(oDelim.isStr()) {
					push_line(`__buff.put(to!string((` ~ inBetweenDelims ~ `)));`);
				} else {
					push_line(inBetweenDelims);
				}
				prevTempl.munchHeadOf(templ, cDelimPos.pos + cDelim.toString().length);
			}
			else
			{
				//Delim is somewhere in the string
				push_line(`__buff.put("` ~ templ[0..oDelimPos.pos] ~ `");`);
				prevTempl.munchHeadOf(templ, oDelimPos.pos);
			}
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
	#line 1 "TemplMixin"
	enum Templ = mixin(gen_templ_func_string!void(template_string));
	#line 154 "src/templ/templ.d"
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
	//Test to!string of eval delimers
	const render = Templ!(`<%= "foo" %>`);
	static assert(render() == "foo");
}
unittest {
	// Test delimer parsing
	const render = Templ!("<% if(true) { %>foo<% } %>");
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
	// Test shorthand
	const templ = `
		% if(true) {
			Hello!
		% }
	`;
	const render = Templ!(templ);
	assert(render().stripWs() == "Hello!");
}
unittest {
	// Test shorthand string eval
	const templ = `
		% if(true) {
			%= "foo"
		% }
	`;
	const render = Templ!(templ);
	assert(render().stripWs() == "foo");
}
unittest {
	// Test shorthand only after newline
	const templ = `foo%bar`;
	const render = Templ!(templ);
	static assert(render() == "foo%bar");
}
unittest {
	// Ditto
	const templ = `<%= "foo%bar" %>`;
	const render = Templ!(templ);
	static assert(render() == "foo%bar");
}
