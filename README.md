Temple [![Build Status](https://travis-ci.org/dymk/temple.png?branch=master)](https://travis-ci.org/dymk/temple)
======
Surprisingly Flexable, Compile Time, Zero Overhead, Embedded Template Engine for D

About
-----
Temple is a templating engine written in D, allowing D code to be embedded and
executed in text files. The engine converts text to code at compile time, so there
is zero overhead interpreting templates at runtime, allowing for very fast rendering.

Temple supports passing any number of arbitrary variables to templates, as well as
nesting and yielding templates within each other, capturing blocks of template code, and optional
fine-grain filtering of generated text (e.g for escaping generated strings/safe strings).

[Vibe.d](http://vibed.org/) compatible! See the [Vibe.d Usage](#vibed) section.

Temple works with DMD 2.066 and later, and with an LDC >= `0.15-alpha1` (probably
GDC as well, but it has not been tested).

Table of Contents
-----------------

 - [Usage](#usage)
 - [The Temple Syntax](#template-syntax)
 - [Contexts](#contexts)
 - [The `Temple` Function](#the-temple-template)
 - [The `TempleFile` Function](#the-templefile-template)
 - [Nested Templates](#nested-templates)
 - [Yielding, Layouts, and Partials](#yielding-layouts-and-partials)
 - [Capture Blocks](#capture-blocks)
 - [Helpers](#helpers-a-la-rails-view-helpers)
 - [Filters](#filters)
 - [TempleFilter](#templefilter)
 - [Vibe.d Usage](#vibed)
 - [Example: Simple Webpages](#example-simple-webpages)

Usage
-----
If using dub, include `temple` as a dependency in `dub.json`, or all of the files in
`src/temple` in your build process, and `import temple;`.

Going from a template string to a rendered template follows the process:
 - Compile the template with the `compile_temple` or `compile_temple_file` functions, resulting in a `CompiledTemple`
 - Call 'toString' or 'render' on the resulting `CompiledTemple`
 - Optionally pass in a `TempleContext` to pass variables to the template

Optional [Filters](#filters) can be supplied to `compile_template[_file]` to filter dynamic template content.

The Temple Syntax
---------------
The template syntax is based off of that of [eRuby](https://en.wikipedia.org/wiki/ERuby) (but can be changed by modifying `temple/delims.d`).
D statements go between `<% %>` delimers. If you wish to capture the result of a D expression, place it between `<%= %>` delimers, and it will be converted to a `string` using std.conv's `to`.

> Note that expressions within `<%= %>` should _not_ end with a semicolon, while statements within `<% %>` should.

####Quick Reference:

| Input | Output |
| ----- | ------ |
| `foo` | `foo`  |
| `<% "foo"; %>`  | `<no output>` |
| `<%= "foo" %>` | `foo`  |
| `<%= "<%=" %>` | `<%=`  |
| `<%= "<%" %>` | `<%`  |
| `%>` | `%>`  |

###### Foreach
```d
<% foreach(i; 0..3) { %>
	Index: <%= i %>
<% } %>
```
```
Index: 0
Index: 1
Index: 2
```

###### If/else if/else statements
```d
<% auto a = "bar"; %>
<% if(a == "foo") { %>
	Foo!
<% } else if(a == "bar") { %>
	Bar!
<% } else { %>
	Baz!
<% } %>
```
```
Bar!
```

###### Overall usage
```d
auto hello = compile_temple!`Hello, <%= var.name %>!`
auto ctx = new TempleContext();
ctx.name = "Jimmy";

writeln(hello.toString(ctx));
```
```
Hello, Jimmy!
```

Contexts
--------
The `TempleContext` type is used to pass variables to templates. The struct responds to
`opDispatch`, and returns variables in the `Variant` type. Use `Variant#get` to
convert the variable to its intended type. `TemplateContext#var(string)` is used
to retrieve variables in the context, and can be called direty with `var` in the
template:

```d
auto context = new TempleContext();
context.name = "dymk";
context.should_bort = true;
```
Passed to:
```d
<% /* Variant can be converted to a string automatically */ %>
Hello, <%= var("name") %>

<% /* Conversion of a Variant to a bool */ %>
<% if(var("should_bort").get!bool) { %>
	Yep, gonna bort
<% } else { %>
	Nope, not gonna bort
<% } %>

<% /* Variants are returned by reference, and can be (re)assigned */ %>
<% var("written_in") = "D" %>
Temple is written in: <%= var("written_in") %>
}
```

Results in:
```
Hello, dymk
Yep, gonna bort
Temple is written in: D
```

Variables can also be accessed directly via the dot operator, much like
setting them.

```d
auto context = new TempleContext();
context.foo = "Foo!";
context.bar = 10;
```

```erb
<%= var.foo %>
<%= var.bar %>

<% var.baz = true; %>
<%= var.baz %>
}
```

Prints:
```
Foo!
10
true
```

For more information, see the Variant documentation on [the dlang website](http://dlang.org/phobos/std_variant.html)

Using CompiledTemple
-------------------
Both `compile_temple!"template string"` and `compile_temple_file!"filename"` return a `CompiledTemple`.
The `CompiledTemple` exposes two rendering methods, `toString`, and `render`, both of which take an optional `TemplateContext`.

#####`string CompiledTemple#toString(TempleContext = null)`
-------
Evaluates the template and returns the resulting string
```d
import
  temple.temple,
  std.stdio,
  std.string;

void main()
{
	auto tlate = compile_temple!"foo, bar, baz";
	writeln(tlate.toString()); // Prints "foo, bar, baz"
}
```

An example passing a `TempleContext`:
```d
void main()
{
	auto tlate = compile_temple!q{
		Hello, <%= var("name") %>
	};

	auto context = new TempleContext();
	context.name = "dymk";

	writeln(tlate.toString(ctx)); // Prints "Hello, dymk"
}
```

#####`void CompiledTemple#render(Sink, TempleContext = null)`
-----
Incrementally evaluates the template into Sink, which can be one of the following:
 - an `std.stdio.File`
 - an arbitrary OutputRange (as determined by `std.range.isOutputRange!(T, string)`)
 - a function or delegate that can take a string: `void delegate(string str) {}`

Using `render` greatly decreases the number of allocations that must be made compared to `toString`.

```d
auto tlate = compile_temple!q{
	Hello, <%= var("name") %>
};

tlate.render(stdout); // render into stdout

// incrementally render into function/delegate
tlate.render(function(str) {
	write(str);
});
```

`compile_temple_file`
-----------------------
`compile_temple_file` is the same as `compile_temple`, but
takes a file name to read as a template instead of the template string directly.
Temple template files typically end with the extension `.emd` ("embedded d").

`template.emd`:
```d
It's <%= var("hour") %> o'clock.
```

`main.d`:
```d
import
  templ.templ,
  std.stdio;

void main() {
	auto tplate = compile_temple_file!"template.emd";

	auto context = new TempleContext();
	context.hour = 5;

	tplate.render(stdout);
}
```
```
It's 5 o'clock
```

Nested Templates
----------------

`#render` can be called within templates to nest templates. By default,
the current context is passed to the nested template, and any filters applied to the nester
are applied to the neste. A different context can be passed explicitly by calling
`#render_with(TemplateContext)` instead.

`a.emd`
```erb
<html>
	<body>
		<p>Hello, from the 'a' template!</p>
		<%= render!"b.emd"() %>
	<body>
</html>
```

`b.emd`
```erb
<p>And this is the 'b' template!</p>
```

Rendering `a.emd` would result in:
```html
<html>
	<body>
		<p>Hello, from the 'a' template!</p>
		<p>And this is the 'b' template!</p>
	<body>
</html>
```

Layouts and Yielding
-------------------------------

Templates can be made into parent layouts, where the child is rendered when `#yield` is called.
Setting the child for a template is done by calling `layout` on the parent.

```d
void main()
{
	auto parent = compile_temple!"before <%= yield %> after";
	auto child  = compile_temple!"between";

	auto composed = parent.layout(&child);
	composed.render(stdout);
}
```
```
before between after
```

Capture Blocks
--------------
Blocks of template can be captured into a variable, by wrapping the desired
code inside of a delegate, and passing that to `capture`. Capture blocks
can be nested. Capture blocks do not render directly to a string, but rather a range,
meaning that evaluating a capture block will result in evaluating the entire capture block
multiple times.

Capture has the signature `string capture(T...)(void delegate(T) block, T args)`,
and can be called from user defined functions as well (See the Helpers section).

Example:

```d
<% auto outer = capture(() { %>
	Outer, first
	<% auto inner = capture(() { %>
		Inner, first
	<% }); %>
	Outer, second

	<%= inner %>
<% }); %>

<%= outer %>
```
```
Outer, first
Outer, second
	Inner, first
```

Helpers (A-la Rails View Helpers)
---------------------------------

Helpers aren't a built in feature of Temple, but they are a very useful pattern for DRYing up templates.
Here's a partial implementation of Rails' `form_for` helper:

```d
<%
import std.string;
struct FormHelper
{
	string model_name;

	auto field_for(string field_name, string type="text")
	{
		if(model_name != "")
		{
			field_name = "%s[%s]".format(model_name, field_name);
		}

		return `<input type="%s" name="%s" />`.format(type, field_name);
	}

	auto submit(string value = "Submit")
	{
		return `<input type="button" value="%s" />`.format(value);
	}
}

auto form_for(
	string action,
	string name,
	void delegate(FormHelper) block)
{
	auto form_body = capture(block, FormHelper(name));
	return `
		<form action="%s" method="POST">
			%s
		</form>`.format(action, form_body);
}
%>

<%= form_for("/shorten", "", (f) { %>
	Shorten a URL:
	<%= f.field_for("url") %>
	<%= f.submit("Shorten URL") %>
<% }); %>

<%= form_for("/person", "person", (f) { %>
	Name: <%= f.field_for("name") %>
	Age: <%= f.field_for("age") %>
	DOB: <%= f.field_for("date_of_birth", "date") %>
	<%= f.submit %>
<% }); %>
```

Renders:
```html
<form action="/shorten" method="POST">
	Shorten a URL:
	<input type="text" name="url" />
	<input type="button" value="Shorten URL" />
</form>

<form action="/person" method="POST">
	Name: <input type="text" name="person[name]" />
	Age: <input type="text" name="person[age]" />
	DOB: <input type="date" name="person[date_of_birth]" />
	<input type="button" value="Submit" />
</form>
```

Filters
-------

Filters are a way to filter and transform the dyanmic parts of the template, before
it is written to the output buffer.
A filter takes the form of a `struct` or `class` that defines various overloads of the static
method `temple_filter`. The `temple_filter` methods can either:
 - Take two parameters: a `TempleOutputStream` to write their result to, and the input to filter, e.g.
   - `void temple_filter(ref TempleOutputStream ob, string str) { ob.put(str); }
 - Take one parameter and return a string:


Example, wrapping evaluated text in quotes:

```d
struct QuoteFilter
{
	static string temple_filter(string raw)
	{
		return `"` ~ raw ~ `"`;
	}

	static string temple_filter(T)(T raw)
	{
		return temple_filter(to!string(raw));
	}
}

auto render = compile_temple!(QuoteFilter, q{
	Won't be quoted
	<%= "Will be quoted" %>
	<%= 10 %>
});
writeln(templeToString(&render));
```
```
Won't be quoted
"Will be quoted"
"10"
```

The `temple_filter` method isn't limited to filtering only strings, however.
Any arbitrary type can be passed in. They can also define any arbitrary methods to use
in the template, provided they don't clash with the methods that `TempleContext` defines.

Example, implementing safe/unsafe strings for conditional escaping of input:

```d
private struct SafeDemoFilter
{
	static private struct SafeString
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

auto templ = compile_temple!(q{
	foo (filtered):   <%= "mark me" %>
	foo (unfiltered): <%= safe("don't mark me") %>
}, SafeDemoFilter);

templ.render(stdout);
```
```
foo (filtered):   !mark me!
foo (unfiltered): don't mark me
```

Filters are propogated to nested templates:

`a.emd`:
```d
<%= safe("foo1") %>
<%= "foo2" %>
foo3
<%= render!"b.emd" %>
foo4
```

`b.emd`
```d
<%= safe("bar1") %>
<%= "bar2" %>
bar3
```

`a.emd` rendered with the `SafeDemoFilter`:
```
foo1
!foo2!
foo3
bar1
!bar2!
bar3
foo4
```

TempleFilter
------------

`TempleFilter` is not a filter itself, but rather allows a filter to be applied to entire family of `Temple`
templates, grouping them under a single name.

Example usage:
```d
struct MyFilter {
	static string temple_filter(string unfiltered) {
		return "!" ~ unfiltered ~ "!";
	}
}

// All Temple templates under Filtered will have MyFilter applied to them
alias Filtered = TempleFilter!MyFilter;

auto child = Filtered.Temple!`
	foo
	<%= "bar" %>
`;

auto parent = Filtered.TempleLayout!`
	header
	<%= yield %>
	footer
`

parent.layout(&child).render(stdout);
```

Which would render:
```
header
foo
!bar!
footer
```

Vibe.d Integration
------------------

Temple will expose functions for integrating with Vibe.d if compiled together (e.g. `Have_vibe_d` is defined)
The addition to the Temple API is:
 - `void renderTemple(string temple)(HTTPServerRequest, Context = null)`
 - `void renderTempleFile(string filename)(HTTPServerRequest, Context = null)`
 - `void renderTempleLayoutFile(string layoutfile, string partialfile)(HTTPServerRequest, Context = null)`
 - `struct TempleHtmlFilter`

where `Context` can be an `HTTPServerResponse`, or a `TempleContext`. If it is a `HTTPServerResponse`, then the contents of the `params` hash will be the context for the template.

Usage is similar to Vibe.d's `render` function:

```d
void doRequest(HTTPServerRequest req, HTTPServerResponse res) {

	// Client requested with query string `?name=foo`

	req.renderTemple!(`
		Hello, world!
		And hello, <%= var.name %>!
	`)(res);

}
```

Would result in this HTTP response:
```
Hello, world!
And hello, foo!
```

---

Dynamic content is passed through Vibe's HTML filter before being renderd, unless it is
marked as safe, by calling `safe("your string")`.

```d
void doRequest(HTTPServerRequest req, HTTPServerResponse res) {

	// Client requested with query string `?name=foo`

	req.renderTemple!(`
		<html>
			<body>
				Here's a thing!
				<%= "<p>Escape me!</p>" %>
				<%= safe("<span>Don't escape me!</span>") %>
			</body>
		</html>
		Hello, world!
		And hello, <%= var.name %>!
	`)(res);

}
```

Would result in the HTTP response:
```html
<html>
	<body>
		Here's a thing!
		&lt;p&gt;Escape me!&lt;/p&gt;
		<span>Don't escape me!</span>
	</body>
</html>
```

Example: Simple Webpages
------------------------

Here's a slightly more complex example, demonstrating how to use the library
to render HTML templates inside of a common layout.

```d
void main()
{
	auto parent = compile_temple_file!"layout.html.emd";
	auto child  = compile_temple_file!"_partial.html.emd";

	parent.layout(&child).render(stdout);
}
```

`layout.html.emd`
```d
<html>
	<head>
		<title>dymk's awesome website</title>
	</head>
	<body>
		<%= render!"common/_sidebar.html.emd"() %>
		<%= yield %>
		<%= render!"common/_footer.html.emd"() %>
	</body>
</html>
```

`common/_sidebar.html.emd`
```html
<ul>
	<li><a href="/">Home</a></li>
	<li><a href="/about">About</a></li>
	<li><a href="/contact">Contact</a></li>
</ul>
```

`common/_footer.html.emd`
```html
<footer>
	2013 (C) dymk .: built with Temple :.
</footer>
```

`_partial.html.emd`
```html
<section>
	TODO: Write a website
</section>
```

Output:
```html
<html>
	<head>
		<title>dymk's awesome website</title>
	</head>
	<body>
		<ul>
			<li><a href="/">Home</a></li>
			<li><a href="/about">About</a></li>
			<li><a href="/contact">Contact</a></li>
		</ul>
		<section>
			TODO: Write a website
		</section>
		<footer>
			2013 (C) dymk .: built with Temple :.
		</footer>
	</body>
</html>
```

Notes
-----
The D compiler must be told which directories are okay to import text from.
Use the `-J<folder>` compiler switch or `stringImportPaths` in Dub to include your template
directory so Temple can access them.

For more examples, take a look at`src/temple/test/common.d`'s unittests; they provide
very good coverage of the library's abilities.

License
-------
*Temple* is distributed under the [Boost Software License](http://www.boost.org/LICENSE_1_0.txt).
