module temple.tests.common;


version(TempleUnittest):

public import std.stdio, std.file : readText;
public import
	temple,
	temple.util,
	temple.output_stream;

bool isSameRender(in CompiledTemple t, TempleContext tc, string r2) {
	return isSameRender(t, r2, tc);
}
bool isSameRender(in CompiledTemple t, string r2, TempleContext tc = null) {
	return isSameRender(t.toString(tc), r2);
}
bool isSameRender(string r1, string r2)
{
	auto ret = r1.stripWs == r2.stripWs;

	if(ret == false)
	{
		writeln("Renders differ: ");
		writeln("Got: -------------------------");
		writeln(r1);
		writeln("Expected: --------------------");
		writeln(r2);
		writeln("------------------------------");
	}

	return ret;
}

deprecated("Please use template.toString()")
string templeToString(CompiledTemple function() getr, TempleContext tc = null) {
	return getr().toString(tc);
}

unittest
{
	auto render = compile_temple!"";
	assert(render.toString() == "");
}

unittest
{
	//Test to!string of eval delimers
	auto render = compile_temple!`<%= "foo" %>`;
	assert(render.toString == "foo");
}

unittest
{
	// Test delimer parsing
	auto render = compile_temple!("<% if(true) { %>foo<% } %>");
	assert(render.toString == "foo");
}
unittest
{
	//Test raw text with no delimers
	auto render = compile_temple!(`foo`);
	assert(render.toString == "foo");
}

unittest
{
	//Test looping
	const templ = `<% foreach(i; 0..3) { %>foo<% } %>`;
	auto render = compile_temple!templ;
	assert(render.toString == "foofoofoo");
}

unittest
{
	//Test looping
	const templ = `<% foreach(i; 0..3) { %><%= i %><% } %>`;
	auto render = compile_temple!templ;
	assert(render.toString == "012");
}

unittest
{
	//Test escaping of "
	const templ = `"`;
	auto render = compile_temple!templ;
	assert(render.toString == `"`);
}

unittest
{
	//Test escaping of '
	const templ = `'`;
	auto render = compile_temple!templ;
	assert(render.toString == `'`);
}

unittest
{
	auto render = compile_temple!`"%"`;
	assert(render.toString == `"%"`);
}

unittest
{
	// Ditto
	auto render = compile_temple!`<%= "foo%bar" %>`;
	assert(render.toString == "foo%bar");
}

unittest
{
	auto context = new TempleContext();
	context.foo = 123;
	context.bar = "test";

	auto render = compile_temple!`<%= var("foo") %> <%= var("bar") %>`;
	assert(render.toString(context) == "123 test");
}

unittest
{
	// Loading templates from a file
	auto render = compile_temple_file!"test1.emd";
	auto compare = readText("test/test1.emd.txt");
	assert(isSameRender(render.toString, compare));
}

unittest
{
	auto render = compile_temple_file!"test2.emd";
	auto compare = readText("test/test2.emd.txt");

	auto ctx = new TempleContext();
	ctx.name = "dymk";
	ctx.will_work = true;

	assert(isSameRender(render.toString(ctx), compare));
}

unittest
{
	auto render = compile_temple_file!"test3_nester.emd";
	auto compare = readText("test/test3.emd.txt");
	assert(isSameRender(render.toString, compare));
}

unittest
{
	auto render = compile_temple_file!"test4_root.emd";
	auto compare = readText("test/test4.emd.txt");

	auto ctx = new TempleContext();
	ctx.var1 = "this_is_var1";

	assert(isSameRender(render.toString(ctx), compare));
}

unittest
{
	auto parent = compile_temple!"before <%= yield %> after";
	auto partial = compile_temple!"between";

	assert(isSameRender(parent.layout(&partial), "before between after"));
}

unittest
{
	auto parent = compile_temple!"before <%= yield %> after";
	auto partial = compile_temple!"between";

	assert(isSameRender(parent.layout(&partial), "before between after"));
}

unittest
{
	auto parent   = compile_temple_file!"test5_layout.emd";
	auto partial1 = compile_temple_file!"test5_partial1.emd";
	auto partial2 = compile_temple_file!"test5_partial2.emd";

	auto p1 = parent.layout(&partial1);
	auto p2 = parent.layout(&partial2);

	assert(isSameRender(p1, readText("test/test5_partial1.emd.txt")));
	assert(isSameRender(p2, readText("test/test5_partial2.emd.txt")));
}

// Layouts and contexts
unittest
{
	auto parent  = compile_temple_file!"test6_layout.emd";
	auto partial = compile_temple_file!"test6_partial.emd";

	auto context = new TempleContext();
	context.name = "dymk";
	context.uni = "UCSD";
	context.age = 19;

	assert(isSameRender(parent.layout(&partial), context, readText("test/test6_partial.emd.txt")));
}

// opDispatch variable getting
unittest
{
	auto render = compile_temple!"<%= var.foo %>";

	auto context = new TempleContext();
	context.foo = "Hello, world";

	assert(isSameRender(render, context, "Hello, world"));
}

unittest
{
	// 22 Nov, 2014: Disabled this bit, because DMD now ICEs when
	// evaluating the erronious template (but not before spitting out
	// a lot of errors). This will have to do for finding out that a templtae
	// has a lot of errors in it.
	// Uncomment to view the line numbers inserted into the template
	//TODO: check if this works in future DMD releases
	//auto render = compile_temple_file!"test7_error.emd";
	//assert(!__traits(compiles, {
	//	auto t = compile_temple_file!"test7_error.emd";
	//}));
}

unittest
{
	import temple.func_string_gen;
	// Test returning early from templates
	auto render = compile_temple!`
		one
		<% auto blah = true; %>
		<% if(blah) { %>
			two
			<% return; %>
		<% } %>
		three
	`;

	assert(isSameRender(render.toString,
		`one
		two`));
}

unittest
{
	auto render = compile_temple_file!"test15_largefile.emd";
}
