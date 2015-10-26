module temple.tests.filter;

version(TempleUnittest):

import temple.tests.common;

private struct SafeDemoFilter
{
	static struct SafeString
	{
		string value;
	}

	static string temple_filter(SafeString ts)
	{
		return ts.value;
	}

	static string temple_filter(string str)
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
		static string temple_filter(string raw_str)
		{
			return "!" ~ raw_str ~ "!";
		}
	}

	auto render1 = compile_temple!(`<%= "foo" %> bar`, Filter);
	assert(isSameRender(render1, "!foo! bar"));

	auto render2 = compile_temple_file!("test9_filter.emd", Filter);
	assert(isSameRender(render2, `!foo! bar`));
}

unittest
{
	static struct Filter
	{
		static void temple_filter(ref TempleOutputStream os, string raw_str)
		{
			//return "!" ~ raw_str ~ "!";
			os.put("!");
			os.put(raw_str);
			os.put("!");
		}
	}

	auto parent  = compile_temple_file!("test10_fp_layout.emd", Filter);
	auto partial = compile_temple_file!("test10_fp_partial.emd", Filter);

	assert(isSameRender(parent.layout(&partial), readText("test/test10_fp.emd.txt")));
}

unittest
{
	auto render1 = compile_temple!(q{
		foo (filtered):   <%= "mark me" %>
		foo (unfiltered): <%= safe("don't mark me") %>
	}, SafeDemoFilter);

	assert(isSameRender(render1, `
		foo (filtered):   !mark me!
		foo (unfiltered): don't mark me
	`));

	auto render2 = compile_temple!(q{
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

	assert(isSameRender(render2, `
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

	auto render = compile_temple!(q{
		<%= safe("foo1") %>
		<%= "foo2" %>
		<%= render!"test11_propogate_fp.emd"() %>
		<%= "after1" %>
		after2
	}, SafeDemoFilter);

	assert(isSameRender(render, `
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
	auto render = FPGroup.compile_temple!q{
		foo1
		<%= "foo2" %>
	};

	assert(isSameRender(render, `
		foo1
		!foo2!
	`));
}

unittest
{
	// Test unicode charachters embedded in templates

	auto render = compile_temple!(`
		Ю ю	Ю ю	Yu	/ju/, /ʲu/
		Я я	Я я	Ya	/ja/, /ʲa/

		<% if(true) { %>
			А а	А а	A	/a/
			Б б	Б б	Be	/b/
			В в	В в	Ve	/v/
		<% } %>
	`);

	assert(isSameRender(render, `
		Ю ю	Ю ю	Yu	/ju/, /ʲu/
		Я я	Я я	Ya	/ja/, /ʲa/
		А а	А а	A	/a/
		Б б	Б б	Be	/b/
		В в	В в	Ve	/v/
	`));
}

unittest
{
	auto render = compile_temple_file!"test14_unicode.emd";
	auto compare = readText("test/test14_unicode.emd.txt");
	assert(isSameRender(render, compare));
}
