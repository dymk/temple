module temple.tests.capture;

import temple.tests.common;
unittest
{
	// test captures
	auto test = compile_temple!q{
		<% auto a = capture(() { %>
			This is captured in A
		<% }); %>
		<% auto b = capture(() { %>
			This is captured in B
		<% }); %>

		B said: "<%= b %>"
		A said: "<%= a %>"
	};

	assert(isSameRender(test, `
		B said: "This is captured in B"
		A said: "This is captured in A"
	`));
}

unittest
{
	// Nested captures
	auto test = compile_temple!q{
		<% auto outer = capture(() { %>
			Outer, first
			<% auto inner = capture(() { %>
				Inner, first
			<% }); %>
			Outer, second

			<%= inner %>
		<% }); %>

		<%= outer %>
	};

	assert(isSameRender(test, `
		Outer, first
		Outer, second
			Inner, first
	`));
}

unittest
{
	alias render = TempleFile!"test8_building_helpers.emd";
	assert(isSameRender(templeToString(&render), readText("test/test8_building_helpers.emd.txt")));
}

unittest
{
	alias test = compile_temple!q{
		<%= capture(() { %>
			directly printed

			<% auto a = capture(() { %>
				a, captured
			<% }); %>
			<% auto b = capture(() { %>
				b, captured
			<% }); %>

			<%= a %>
			<%= capture(() { %>
				directly printed from a nested capture
			<% }); %>
			<%= b %>

		<% }); %>
	};

	assert(isSameRender(test, `
		directly printed
			a, captured
			directly printed from a nested capture
			b, captured`));
}

/**
 * Test CTFE compatibility
 * Disabled for the API rewrite
 */
version(none):
unittest
{
	const render = compile_temple!q{ <%= "foo" %> };
	static assert(isSameRender(render, "foo"));
}

unittest
{
	alias render = compile_temple!q{
		<% if(true) { %>
			Bort
		<% } else { %>
			No bort!
		<% } %>

		<% auto a = capture(() { %>
			inside a capture block
		<% }); %>

		Before capture
		<%= a %>
		After capture
	};

	const result = templeToString(&render);
	static assert(isSameRender(result, `
		Bort
		Before capture
		inside a capture block
		After capture
	`));
}
