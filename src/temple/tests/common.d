module temple.tests.common;

version(unittest):
public import std.stdio, std.file : readText;
public import
	temple.util,
	temple.temple,
	temple.output_stream;

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

unittest
{
	alias render = Temple!"";
	auto accum = new AppenderOutputStream;

	render(accum);
	assert(accum.data == "");
}

unittest
{
	//Test to!string of eval delimers
	alias render = Temple!`<%= "foo" %>`;
	assert(templeToString(&render) == "foo");
}

unittest
{
	// Test delimer parsing
	alias render = Temple!("<% if(true) { %>foo<% } %>");
	assert(templeToString(&render) == "foo");
}
unittest
{
	//Test raw text with no delimers
	alias render = Temple!(`foo`);
	assert(templeToString(&render) == "foo");
}

unittest
{
	//Test looping
	const templ = `<% foreach(i; 0..3) { %>foo<% } %>`;
	alias render = Temple!templ;
	assert(templeToString(&render) == "foofoofoo");
}

unittest
{
	//Test looping
	const templ = `<% foreach(i; 0..3) { %><%= i %><% } %>`;
	alias render = Temple!templ;
	assert(templeToString(&render) == "012");
}

unittest
{
	//Test escaping of "
	const templ = `"`;
	alias render = Temple!templ;
	assert(templeToString(&render) == `"`);
}

unittest
{
	//Test escaping of '
	const templ = `'`;
	alias render = Temple!templ;
	assert(templeToString(&render) == `'`);
}

unittest
{
	alias render = Temple!`"%"`;
	assert(templeToString(&render) == `"%"`);
}

unittest
{
	// Test shorthand
	const templ = `
		% if(true) {
			Hello!
		% }
	`;
	alias render = Temple!(templ);
	assert(isSameRender(templeToString(&render), "Hello!"));
}

unittest
{
	// Test shorthand string eval
	const templ = `
		% if(true) {
			%= "foo"
		% }
	`;
	alias render = Temple!(templ);
	//static assert(false);
	assert(isSameRender(templeToString(&render), "foo"));
}
unittest
{
	// Test shorthand only after newline
	const templ = `foo%bar`;
	alias render = Temple!(templ);
	assert(templeToString(&render) == "foo%bar");
}

unittest
{
	// Ditto
	alias render = Temple!`<%= "foo%bar" %>`;
	assert(templeToString(&render) == "foo%bar");
}

unittest
{
	auto context = new TempleContext();
	context.foo = 123;
	context.bar = "test";

	alias render = Temple!`<%= var("foo") %> <%= var("bar") %>`;
	assert(templeToString(&render, context) == "123 test");
}

unittest
{
	// Loading templates from a file
	alias render = TempleFile!"test1.emd";
	auto compare = readText("test/test1.emd.txt");
	assert(isSameRender(templeToString(&render), compare));
}

unittest
{
	alias render = TempleFile!"test2.emd";
	auto compare = readText("test/test2.emd.txt");

	auto ctx = new TempleContext();
	ctx.name = "dymk";
	ctx.will_work = true;

	assert(isSameRender(templeToString(&render, ctx), compare));
}

unittest
{
	alias render = TempleFile!"test3_nester.emd";
	auto compare = readText("test/test3.emd.txt");
	assert(isSameRender(templeToString(&render), compare));
}

unittest
{
	alias render = TempleFile!"test4_root.emd";
	auto compare = readText("test/test4.emd.txt");

	auto ctx = new TempleContext();
	ctx.var1 = "this_is_var1";

	assert(isSameRender(templeToString(&render, ctx), compare));
}

unittest
{
	alias render = Temple!"before <%= yield %> after";
	alias partial = Temple!"between";
	auto accum = new AppenderOutputStream;

	auto context = new TempleContext();
	context.partial = &partial;

	render(accum, context);
	assert(isSameRender(accum.data, "before between after"));
}

unittest
{
	alias layout = TempleLayout!"before <%= yield %> after";
	alias partial = Temple!"between";
	auto accum = new AppenderOutputStream;

	layout(accum, &partial);

	assert(isSameRender(accum.data, "before between after"));
}

unittest
{
	alias layout = TempleLayoutFile!"test5_layout.emd";
	alias partial1 = TempleFile!"test5_partial1.emd";
	alias partial2 = TempleFile!"test5_partial2.emd";

	auto accum = new AppenderOutputStream;

	layout(accum, &partial1);

	assert(isSameRender(accum.data, readText("test/test5_partial1.emd.txt")));

	accum.clear;
	layout(accum, &partial2);
	assert(isSameRender(accum.data, readText("test/test5_partial2.emd.txt")));
}

// Layouts and contexts
unittest
{
	alias layout = TempleLayoutFile!"test6_layout.emd";
	alias partial = TempleFile!"test6_partial.emd";
	auto accum = new AppenderOutputStream;
	auto context = new TempleContext();

	context.name = "dymk";
	context.uni = "UCSD";
	context.age = 18;

	layout(accum, &partial, context);
	assert(isSameRender(accum.data, readText("test/test6_partial.emd.txt")));
}

// opDispatch variable getting
unittest
{
	alias render = Temple!"<%= var.foo %>";
	auto accum = new AppenderOutputStream;
	auto context = new TempleContext();

	context.foo = "Hello, world";

	render(accum, context);
	assert(accum.data == "Hello, world");
}

unittest
{
	// Uncomment to view the line numbers inserted into the template
	//alias render = TempleFile!"test7_error.emd";
	assert(!__traits(compiles, TempleFile!"test7_error.emd"));
}

unittest
{
	import temple.func_string_gen;
	// Test returning early from templates
	//auto str = `
	alias render = Temple!`
		one
		% auto blah = true;
		% if(blah) {
			two
			%	return;
		% }
		three
	`;

	//writeln(__temple_gen_temple_func_string(str, "Inline"));
	assert(isSameRender(templeToString(&render),
		`one
		two`));
}
