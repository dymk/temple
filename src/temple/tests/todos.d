module temple.tests.todos;

version(TempleUnittest):

/**
 * Use cases that can hopefully be made to work at some time in the future.
 * These might not work for a number of reasons, such as CTFE, Phobos, DMD, or
 * internal library bugs.
 */

version(none):

// std.variant needs to be made CTFE compatible before this can work
unittest
{
	alias render = Temple!q{
		Name: <%= var.name %>
		Number: <%= var.number %>

		<% auto captured = capture(() { %>
			Here is some captured content!
			var.name: <%= var.name %>
		<% }); %>
		<%= captured %>

		<%= capture(() { %>
			A capture directly being rendered, for completeness.
		<% }); %>
	};

	// The lambda is a hack to set up a temple context
	// at compile time, using a self executing function literal

	const result = templeToString(&render, (() {
		auto ctx = new TempleContext;
		ctx.name = "dymk";
		ctx.number = 1234;
		return ctx;
	})() );

	static assert(isSameRender(result, `
		Name: dymk
		Number: 1234
			Here is some captured content!
			var.name: dymk
		A capture directly being rendered, for completeness.
	`));
}
