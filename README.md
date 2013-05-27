# templ-d
_Compile Time Template Engine for D_


## Usage

###The API
The `Templ` template resides in `templ.templ`.
`Templ` comes in two flavors: One which takes a compile time evaluatable `string`, and one which takes an additional argument: an arbitrary `Context` type, defined by the user.

----

#####`template Templ(string template_string)`
Returns a `function string(void)`, which can then be called to render the template.
```d
import
  templ.templ,
  std.stdio;
void main() {
	const templ_str = "foo, bar, baz";
	auto render = Templ!templ_str;
	writeln(render()); // foo, bar, baz
}
```  

----

#####`template Templ(Context, string template_string)`
Returns a string which can then be `mixin`'d in the scope of where the type Context is declared.
The resulting function is of type `function string(Context)`

```d
import
  templ.templ,
  std.stdio;

void main() {
	struct Ctx {
		auto member_field = "I'm a member field!"
		auto member_method() {
			return "I'm a method!";
		}
	}
	const templ_str = "<%= member_method() %>\n<%= member_field %>";
	auto render = mixin(Templ!(Ctx, templ_str)); //Templ must be mixed in

	auto context = Ctx();
	writeln(render(context));
	// I'm a method!
	// I'm a member field!
}
```

----

### The Template Syntax

The template syntax is based off of that of [eRuby](https://en.wikipedia.org/wiki/ERuby). D code goes between <% and %> delimers. If you wish to capture the result of a D expression, place it between <%= %> chars, and it will be cast to a `string`. Shorthand delimers are also supported. A line beginning with `%` is executed; a line beginning with `%=` is executed and the result is appended to the buffer. 

> Note that expressions evaluated by `<%=` and `%=` shouldn't end with a semicolon, while statements within `<%` and `%` should.

####Quick Reference: 

| Input | Output |
| ----- | ------ |
| `foo` | `foo`  |
| `<% "foo"; %>`  | `<no output>` |
| `<%= "foo" %>` | `foo`  |
| `%= "foo" ~ " " ~ "bar"` | `foo bar` |
| `% "foo";` | `<no output>` |

####Some Longer Examples: 

---
######Foreach
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
---
######Foreach, alt
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
---
######Passing in a context
`main.d`
```d
import templ.templ;
	
struct Ctx {
	bool do_something = false;
}

void main() {
	auto render = mixin(Templ!(Ctx, import("templ.erd")));

	Ctx ctx1 = {do_something: true};
	writeln(render(ctx1));

	Ctx ctx2 = {do_something: false};
	writeln(render(ctx2));
}
```
`templ.erd`
```d
% if(do_something) {
	Did something!
% } else {
	Did not do something!
% }
```
`stdout`
```
Did something!
Did not do something!
```
---
Furthermore `src/templ/templ.d`'s unittests contain many more examples of what is possible with contexts and shorthand notation. 
