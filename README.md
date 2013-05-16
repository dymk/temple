# templ-d
_Compile Time Template Engine for D_


## Usage

###The API

the `Templ` template resides in `templ.templ`.
`Templ` comes in two flavors: One which takes a compile time evaluatable `string`, and one which takes an additional argument: an arbitrary `Context` type.

#####`template Templ(string template_string)`:
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

#####`template Templ(Context, string template_string)`:
Returns a string which can then be `mixin`'d in the scope of where the type Context is declared.  
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
	const templ_str = "<%= member_method() %>
<%= member_field %>";
	auto render = mixin(Templ!(Ctx, templ_str)); //Templ must be mixed in
	
	writeln(render());
	// I'm a method!
	// I'm a member field!
}
```

### The Template Syntax

The template syntax is based off of that of [eRuby](https://en.wikipedia.org/wiki/ERuby). D code goes between <% and %> delimers. If you wish to capture the result of a D expression, place it between <%= %> chars, and it will be cast to a `string`.

_Examples:_
`foo` => `foo`
`<% "foo" %>` => `<no output>`
`<%= "foo" %>` => `foo`
```
<% foreach(i; 0..3) { %>
	<%= i %>
<% } %>
```
=>
```
0
1
2
```
