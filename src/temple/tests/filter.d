module temple.tests.filter;

import temple.tests.common;

private struct SafeDemoFilter
{
	static struct SafeString
	{
		string value;
	}

	static string templeFilter(SafeString ts)
	{
		return ts.value;
	}

	static string templeFilter(string str)
	{
		return "!" ~ str ~ "!";
	}

	static SafeString safe(string str)
	{
		return SafeString(str);
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

	alias render1 = Temple!(`<%= "foo" %> bar`, Filter);
	assert(templeToString(&render1) == "!foo! bar");

	alias render2 = TempleFile!("test9_filter.emd", Filter);
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

	alias layout = TempleLayoutFile!("test10_fp_layout.emd", Filter);
	alias partial = TempleFile!("test10_fp_partial.emd", Filter);

	//writeln(templeToString(&layout, &partial));
	assert(isSameRender(templeToString(&layout, &partial), readText("test/test10_fp.emd.txt")));
}

unittest
{
	alias render1 = Temple!(q{
		foo (filtered):   <%= "mark me" %>
		foo (unfiltered): <%= safe("don't mark me") %>
	}, SafeDemoFilter);

	assert(isSameRender(templeToString(&render1), `
		foo (filtered):   !mark me!
		foo (unfiltered): don't mark me
	`));

	alias render2 = Temple!(q{
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
	}, SafeDemoFilter);

	assert(isSameRender(templeToString(&render2), `
		foo1
		!foo2!
		a !foo3! b
		a foo4 b
	`));
}

unittest
{
	// Test nested filter (e.g., filters are propogated with calls to render()
	// and renderWith())

	alias render = Temple!(q{
		<%= safe("foo1") %>
		<%= "foo2" %>
		<%= render!"test11_propogate_fp.emd"() %>
		<%= "after1" %>
		after2
	}, SafeDemoFilter);

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

unittest
{
	alias FPGroup = TempleFilter!SafeDemoFilter;
	alias render = FPGroup.Temple!q{
		foo1
		<%= "foo2" %>
	};

	assert(isSameRender(templeToString(&render), `
		foo1
		!foo2!
	`));
}

unittest
{
	// Test unicode charachters embedded in templates

	alias render = Temple!(`
		Ю ю	Ю ю	Yu	/ju/, /ʲu/
		Я я	Я я	Ya	/ja/, /ʲa/

		% if(true) {
			А а	А а	A	/a/
			Б б	Б б	Be	/b/
			В в	В в	Ve	/v/
		% }
	`);

	assert(isSameRender(templeToString(&render), `
		Ю ю	Ю ю	Yu	/ju/, /ʲu/
		Я я	Я я	Ya	/ja/, /ʲa/
		А а	А а	A	/a/
		Б б	Б б	Be	/b/
		В в	В в	Ve	/v/
	`));
}

unittest
{
	alias render = TempleFile!"test14_unicode.emd";
	auto compare = readText("test/test14_unicode.emd.txt");
	assert(isSameRender(templeToString(&render), compare));
}
