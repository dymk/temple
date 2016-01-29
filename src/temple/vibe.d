module temple.vibe;

version(Have_vibe_d):

pragma(msg, "Compiling Temple with Vibed support");

private {
	import temple;
	import vibe.http.server;
	import vibe.textfilter.html;
	import vibe.utils.dictionarylist;
	import std.stdio;
	import std.variant;
}

struct TempleHtmlFilter {

	private static struct SafeString {
		const string payload;
	}

	static void temple_filter(ref TempleOutputStream stream, string unsafe) {
		filterHTMLEscape(stream, unsafe);
	}

	static void temple_filter(ref TempleOutputStream stream, Variant variant) {
		temple_filter(stream, variant.toString);
	}

	static string temple_filter(SafeString safe) {
		return safe.payload;
	}

	static SafeString safe(string str) {
		return SafeString(str);
	}

	static SafeString safe(Variant variant) {
		return SafeString(variant.toString);
	}
}

private enum SetupContext = q{
	static if(is(Ctx == HTTPServerRequest)) {
		TempleContext context = new TempleContext();
		copyContextParams(context, req);
	}
	else {
		TempleContext context = req;
	}
};

private template isSupportedCtx(Ctx) {
	enum isSupportedCtx = is(Ctx : HTTPServerRequest) || is(Ctx == TempleContext);
}

void renderTemple(string temple, Ctx = TempleContext)
	(HTTPServerResponse res, Ctx req = null)
	if(isSupportedCtx!Ctx)
{
	mixin(SetupContext);

	auto t = compile_temple!(temple, TempleHtmlFilter);
	t.render(res.bodyWriter, context);
}

void renderTempleFile(string file, Ctx = TempleContext)
	(HTTPServerResponse res, Ctx req = null)
	if(isSupportedCtx!Ctx)
{
	mixin(SetupContext);

	auto t = compile_temple_file!(file, TempleHtmlFilter);
	t.render(res.bodyWriter, context);
}

void renderTempleLayoutFile(string layout_file, string partial_file, Ctx = TempleContext)
	(HTTPServerResponse res, Ctx req = null)
	if(isSupportedCtx!Ctx)
{
	mixin(SetupContext);

	auto layout = compile_temple_file!(layout_file, TempleHtmlFilter);
	auto partial = compile_temple_file!(partial_file, TempleHtmlFilter);
	auto composed = layout.layout(&partial);
	composed.render(res.bodyWriter, context);
}

private void copyContextParams(ref TempleContext ctx, ref HTTPServerRequest req) {
	static if(is(typeof(req.params) == string[string])) {
		if(!req || !(req.params))
			return;
	} else if(is(typeof(req.params) == DictionaryList!(string, true, 32))) {
		if(!req || req.params.length < 1)
			return;
	}

	foreach(key, val; req.params) {
		ctx[key] = val;
	}
}
