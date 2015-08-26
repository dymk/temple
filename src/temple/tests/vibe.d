module temple.tests.vibe;

version(TempleUnittest):
version(Have_vibe_d):

private {
	import temple.tests.common;
	import vibe.http.server;
	import vibe.core.stream;
	import vibe.stream.memory;
	import core.time;
}

/*
 * Drops HTTP headers from the stream output and uses proper newlines
 */
private string rendered(MemoryOutputStream output) {
	import std.string: split, join;

	string data = cast(string)output.data;
	string[] lines = data.split("\r\n");
	lines = lines[4 .. $];

	return lines.join("\n");
}

unittest {
	auto output = new MemoryOutputStream();
	auto resp = createTestHTTPServerResponse(output);
	resp.renderTemple!`
		Something here
		<p>Something more here</p>
		<%= "<p>Escape me!</p>" %>
	`;
	resp.bodyWriter.flush; //flushes resp's output stream wrapping the MemoryOutputStream

	assert(isSameRender(output.rendered, `
		Something here
		<p>Something more here</p>
		&lt;p&gt;Escape me!&lt;/p&gt;
	`));
}

unittest {
	auto output = new MemoryOutputStream();
	auto resp = createTestHTTPServerResponse(output);
	auto ctx = new TempleContext;
	ctx.abc = "<unescaped>";
	ctx.def = "<escaped>";
	resp.renderTemple!`
		<%= safe(var.abc) %>
		<%= var.def %>
	`(ctx);
	resp.bodyWriter.flush; //flushes resp's output stream wrapping the MemoryOutputStream

	assert(isSameRender(output.rendered, `
		<unescaped>
		&lt;escaped&gt;
	`));
}

unittest {
	auto output = new MemoryOutputStream();
	auto resp = createTestHTTPServerResponse(output);
	resp.renderTempleFile!"test12_vibe1.emd";
	resp.bodyWriter.flush; //flushes resp's output stream wrapping the MemoryOutputStream

	assert(isSameRender(output.rendered, `
		Rendering with renderTempleFile in temple.vibe
		<p>Don't escape</p>
		&lt;p&gt;Do escape&lt;/p&gt;
	`));
}

unittest {
	auto output = new MemoryOutputStream();
	auto resp = createTestHTTPServerResponse(output);
	resp.renderTempleLayoutFile!("test13_vibelayout.emd", "test13_vibepartial.emd");
	resp.bodyWriter.flush; //flushes resp's output stream wrapping the MemoryOutputStream

	assert(isSameRender(output.rendered, `
		&lt;div&gt;escaped header&lt;/div&gt;
		<div>header div</div>
		header
		<span>partial</span>
		&lt;p&gt;Escaped paragraph in partial&lt;/p&gt;
		footer
		<div>footer div</div>
	`));
}
