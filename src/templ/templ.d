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
	//int overflow = 0;

	//while(!templ.empty) {
	//	overflow++;
	//	if(overflow > 100) { throw new Exception(templ); }

	//	immutable openDeilmPos = templ.nextDelim(OpenDelims);
	//	immutable odPos = openDeilmPos.pos;
	//	immutable openDelim = cast(OpenDelim)openDeilmPos.delim;
	//	immutable closeDelim = OpenToClose[openDelim];

	//	//assert(false, templ ~ " " ~ to!string(odPos) ~ " " ~ to!string(cast(string[])OpenDelims));
	//	if(odPos == -1) {
	//		push_line(`__buff.put("` ~ templ.escapeQuotes() ~ `");`);
	//		templ = "";
	//	}
	//	else if(odPos != 0) {
	//		//Append everything before the open delimer to the buffer
	//		push_line(`__buff.put("` ~ templ[0..odPos].escapeQuotes() ~ `");`);
	//		templ = templ[odPos..$];
	//	}
	//	else {
	//	}
	//}

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
	#line 153 "src/templ/templ.d"
}

template Templ(Context, string template_string) {
	enum Templ = gen_templ_func_string!Context(template_string);
}

version(none) {
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
}
