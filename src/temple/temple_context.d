module temple.temple_context;

import temple.temple;
import temple.output_stream;

public import std.variant : Variant;
private import std.array, std.string;

struct TempleContext
{
private:
	Variant[string] vars;

public:
	Variant opDispatch(string op)()
	{
		return get(op);
	}

	void opDispatch(string op, T)(T other) @property
	{
		vars[op] = other;
	}

	bool isSet(string name)
	{
		return (name in vars && vars[name] != Variant());
	}

	ref Variant var(string name)
	{
		if(name !in vars)
			vars[name] = Variant();

		return vars[name];
	}

	static string renderWith(string file)(TempleContext ctx = TempleContext())
	{
		alias render_func = TempleFile!(file);
		auto buff = appender!string;
		render_func(buff, ctx);
		return buff.data();
	}

	string render(string file)()
	{
		return renderWith!file(this);
	}

	// DMD bug; can't use
	//string render(string file)(TempleContext ctx)
	//{
	//	return renderWith!file(ctx);
	//}
}