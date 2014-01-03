module temple.tests.filter_policy;

import temple.tests.common;

private struct SafeDemoFilter
{
	static struct TaintedString
	{
		string value;
		bool clean = false;
	}

	static string templeFilter(TaintedString ts)
	{
		if(ts.clean)
		{
			return ts.value;
		}
		else
		{
			return "!" ~ ts.value ~ "!";
		}
	}

	static string templeFilter(string str)
	{
		return templeFilter(TaintedString(str));
	}

	static TaintedString safe(string str)
	{
		return TaintedString(str, true);
	}
}

unittest
{
	static struct Filter
	{
		static string templeFilter(string raw_str)
		{
			return "!" ~ raw_str ~ "!";
		}
	}

	alias render1 = Temple!(Filter, `<%= "foo" %> bar`);
	assert(templeToString(&render1) == "!foo! bar");

	alias render2 = TempleFile!(Filter, "test9_filter_policy.emd");
	assert(isSameRender(templeToString(&render2), `!foo! bar`));
}

unittest
{
	static struct Filter
	{
		static string templeFilter(string raw_str)
		{
			return "!" ~ raw_str ~ "!";
		}
	}

	alias layout = TempleLayoutFile!(Filter, "test10_fp_layout.emd");
	alias partial = TempleFile!(Filter, "test10_fp_partial.emd");

	//writeln(templeToString(&layout, &partial));
	assert(isSameRender(templeToString(&layout, &partial), readText("test/test10_fp.emd.txt")));
}

unittest
{
	alias render1 = Temple!(SafeDemoFilter, q{
		foo (filtered):   <%= "mark me" %>
		foo (unfiltered): <%= safe("don't mark me") %>
	});

	assert(isSameRender(templeToString(&render1), `
		foo (filtered):   !mark me!
		foo (unfiltered): don't mark me
	`));

	alias render2 = Temple!(SafeDemoFilter, q{
		<%
		auto helper1(void delegate() block)
		{
			return "a " ~ capture(block) ~ " b";
		}
		%>

		<%= capture(() { %>
			foo1
			<%= "foo2" %>
		<% }); %>

		<%= helper1(() { %>
			<%= "foo3" %>
		<% }); %>

		<%= helper1(() { %>
			<%= safe("foo4") %>
		<% }); %>
	});

	assert(isSameRender(templeToString(&render2), `
		foo1
		!foo2!
		a !foo3! b
		a foo4 b
	`));
}

unittest
{
	// Test nested filter policies (e.g., filter policies are
	// propogated with calls to render() and renderWith())

	alias render = Temple!(SafeDemoFilter, q{
		<%= safe("foo1") %>
		<%= "foo2" %>
		<%= render!"test11_propogate_fp.emd"() %>
		<%= "after1" %>
		after2
	});

	assert(isSameRender(templeToString(&render), `
		foo1
		!foo2!
		bar1
		!bar2!
		bar3
		!after1!
		after2
	`));
}