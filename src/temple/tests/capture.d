module temple.tests.capture;

import temple.tests.common;

unittest
{
	// test captures
	alias render = Temple!q{
		<% auto a = capture(() { %>
			This is captured in A
		<% }); %>
		<% auto b = capture(() { %>
			This is captured in B
		<% }); %>

		B said: "<%= b %>"
		A said: "<%= a %>"
	};

	auto accum = new AppenderOutputStream;
	render(accum);

	assert(isSameRender(accum.data, `
		B said: "This is captured in B"
		A said: "This is captured in A"
	`));
}

unittest
{
	// Nested captures
	alias render = Temple!q{
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

	auto accum = new AppenderOutputStream;
	render(accum);

	assert(isSameRender(accum.data, `
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
	alias render = Temple!q{
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

	auto accum = new AppenderOutputStream;
	render(accum);

	assert(isSameRender(accum.data, `
		directly printed
			a, captured
			directly printed from a nested capture
			b, captured`));
}

/**
 * Test CTFE compatibility
 */
unittest
{
	alias render = Temple!q{ <%= "foo" %> };
	const result = templeToString(&render);
	static assert(isSameRender(result, "foo"));
}

unittest
{
	alias render = Temple!q{
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
