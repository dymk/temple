Temple [![Build Status](https://travis-ci.org/dymk/temple.png?branch=master)](https://travis-ci.org/dymk/temple)
======
A Compile Time, Zero Overhead, Embedded Template Engine for D

About
-----
Temple is a templating engine written in D, allowing D code to be embedded and
executed in text files. The engine converts text to code at compile time, so there
is zero overhead interpreting templates at runtime, allowing for very fast template
rendering.

Temple supports passing any number of variables to templates, as well as rendering
nested templates within each other.

[Vibe.d](http://vibed.org/) compatible! `OutputStream` is implemented by vibe.d's
connections, so just pass your `TCPConnection` or `HTTPServerResponse` where the
following examples pass an `AppenderOutputStream`.

Usage
-----
Include `temple` in your `package.json`, or all of the files in
`src/temple` in your build process.

The main API exposed by Temple consists of a few templates, and a struct:
 - `template Temple(string template_string)`
 - `template TempleFile(string file_name)`
 - `template TempleLayout(string layout_string)`
 - `template TempleLayoutFile(string layout_file)`
 - `struct TempleContext`
 - `interface OutputStream`

Temple(File)s take an `OutputStream` and an optional `TempleContext`.
TempleLayout(File)s take an `OutputStream`, a Temple(File) function pointer (the
partial rendered in the layout), and an optional `TempleContext`.

Template Syntax
---------------
The template syntax is based off of that of [eRuby](https://en.wikipedia.org/wiki/ERuby).
D statements go between `<% %>` delimers. If you wish to capture the result of a D
expression, place it between `<%= %>` delimers, and it will be converted to a `string` using std.conv's `to`.

Shorthand delimers are also supported: A line beginning with `%` is executed; a line beginning with `%=` is executed and the result is written to the output stream.

> Note that expressions within `<%= %>` and `%=` can't end with a semicolon, while statements within `<% %>` and `%` should.

####Quick Reference:

| Input | Output |
| ----- | ------ |
| `foo` | `foo`  |
| `<% "foo"; %>`  | `<no output>` |
| `<%= "foo" %>` | `foo`  |
| `%= "foo" ~ " " ~ "bar"` | `foo bar` |
| `% "foo";` | `<no output>` |

###### Foreach
```d
% foreach(i; 0..3) {
	Index: <%= i %>
% }
```
```
Index: 0
Index: 1
Index: 2
```

###### Foreach, alt
```d
% import std.conv;
<% foreach(i; 0..3) { %>
	%= "Index: " ~ to!string(i)
<% } %>
```
```
Index: 0
Index: 1
Index: 2
```

###### If/else if/else statements
```d
% auto a = "bar";
% if(a == "foo") {
	Foo!
% } else if(a == "bar") {
	Bar!
% } else {
	Baz!
% }
```
```
Bar!
```

Template Contexts
-----------------
Template contexts are used to pass variables to templates. The struct responds to
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
% if(var("should_bort").get!bool) {
	Yep, gonna bort
% } else {
	Nope, not gonna bort
% }

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

The Temple Template
-------------------
`Template!"template string"` evaluates to a function that takes an `OutputStream`,
and an optional `TemplateContext`. The easiest way to render the template into a
string is to pass it an `AppenderOutputStream` from `temple.output_stream`.

```d
import
  temple.temple,
  std.stdio,
  std.string;

void main()
{
	alias render = Temple!"foo, bar, baz";

	auto accum = new AppenderOutputStream;
	render(accum);

	writeln(accum.data); // Prints "foo, bar, baz"
}
```

Here's an example passing a `TempleContext`:

```d
void main()
{
	const templ_str = q{
		Hello, <%= var("name") %>
	};
	alias render = Temple!templ_str;
	auto accum = new AppenderOutputStream;

	auto context = new TempleContext();
	context.name = "dymk";

	render(accum, context);
	writeln(accum.data); // Prints "Hello, dymk"
}

```


The TempleFile Template
-----------------------
`template TempleFile(string file_name)` is the same as `template Temple`, but
takes a file name to read as a template instead of the template string directly.
Temple template files end with the extension `.emd`, for "embedded d".

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
	alias render = TempleFile!"template.emd";

	auto context = new TempleContext();
	context.hour = 5;

	auto accum = new AppenderOutputStream;
	render(accum);

	writeln(accum.data);
}
```

```
It's 5 o'clock
```

Nested Templates
----------------

`TemplateContext#render` is used for rendering nested templates. By default,
the current context is passed to the nested template, but a different context can
be passed explicitly by calling `TemplateContext#renderWith(TemplateContext)` instead.

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

Yielding, Layouts, and Partials
-------------------------------

A `TemplateContext`'s `partial` field can be assigned to a Temple function. If
`yield` is called inside of a template, then the TemplateContext's partial will be
rendered and inserted in place of the `yield` call. If no `partial` is present
in the context, then an empty string will be inserted instead.

```d
void main()
{
	alias render = Temple!"before <%= yield %> after";
	alias inner  = Temple!"between";
	auto accum = new AppenderOutputStream();
	auto context = new TempleContext();

	context.partial = &inner;

	render(accum, context);
	writeln(accum.data);
}
```
```
before between after
```

TempleLayout provides a shortcut to setting up a `TempleContext` with a partial
An optional context can be passed to layout, which will also be passed to any
nested partials.

```d
void main()
{
	alias layout = TempleLayout!`before <%= yield %> after`;
	alias partial = Temple!`between`;
	auto accum = new AppenderOutputStream();

	layout(accum, &partial);
	writeln(accum.data);
}
```
```
before between after
```

And, for completeness, `TempleLayoutFile` exists for loading a template directly
from a file.

Example
-------

Here's a slightly more complex example, demonstrating how to use

```d
void main()
{
	alias layout = TempleLayoutFile!"layout.html.emd";
	alias partial = TempleFile!"_partial.html.emd";
	auto accum = new AppenderOutputStream();

	layout(accum, &partial);
	writeln(accum.data);
}
```

`layout.html.emd`
```d
<html>
	<head>
		<title>dymk's awesome website</title>
	</head>
	<body>
		%= render!"common/_sidebar.html.emd"()
		%= yield
		%= render!"common/_footer.html.emd"()
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

For more examples, take a look at`src/temple/temple.d`'s unittests; they provide
very good coverage of the library's abilities.

License
-------
*Temple* is distributed under the [Boost Software License](http://www.boost.org/LICENSE_1_0.txt).
