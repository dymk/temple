module temple.tests.vibe;

version(TempleUnittest):

/**
 * Tests here depend on vibe.d's HTTPServer{Request,Response} being nonfinal
 * in order to mock methods on them. However, this would require a modification
 * to the vibe.d library, so by default they're disabled.
 */

version(none):
version(Have_vibe_d):

private {
	import temple.tests.common;
	import vibe.http.server;
	import vibe.core.stream;
	import core.time;
}

/*
 * Stub of ConnectionStream to satisfy HTTPServerResponse
 */
private final class NullConnStream : ConnectionStream {
	/// InputStream
	@property bool empty() { return true; }
	@property ulong leastSize() { return 0; }
	@property bool dataAvailableForRead() { return false; };
	const(ubyte)[] peek() { return []; };
	void read(ubyte[] dst) {};

	/// OutputStream
	void write(in ubyte[] bytes) {}
	void flush() {}
	void finalize() {}
	void write(InputStream stream, ulong nbytes = 0) {};

	// ConnectionStream
	@property bool connected() const { return false; }
	void close() {}
	bool waitForData(Duration timeout = 0.seconds) { return false; }
}

/*
 * Stub of HTTPServerResponse to override bodyWriter
 */
private final class DummyHTTPServerResponse : HTTPServerResponse {
private:
	AppenderOutputStream appender;

public:
	this() {
		super(
			new NullConnStream(),
			new NullConnStream(),
			null, null);
		appender = new AppenderOutputStream();
	}

	override @property vibe.core.stream.OutputStream bodyWriter() {
		return appender;
	}

	string rendered() {
		return appender.data();
	}
}

unittest {
	auto resp = new DummyHTTPServerResponse();
	resp.renderTemple!`
		Something here
		<p>Something more here</p>
		<%= "<p>Escape me!</p>" %>
	`;

	assert(isSameRender(resp.rendered, `
		Something here
		<p>Something more here</p>
		&lt;p&gt;Escape me!&lt;/p&gt;
	`));
}

unittest {
	auto resp = new DummyHTTPServerResponse();
	resp.renderTempleFile!"test12_vibe1.emd";

	assert(isSameRender(resp.rendered, `
		Rendering with renderTempleFile in temple.vibe
		<p>Don't escape</p>
		&lt;p&gt;Do escape&lt;/p&gt;
	`));
}

unittest {
	auto resp = new DummyHTTPServerResponse();
	resp.renderTempleLayoutFile!("test13_vibelayout.emd", "test13_vibepartial.emd");

	assert(isSameRender(resp.rendered, `
		&lt;div&gt;escaped header&lt;/div&gt;
		<div>header div</div>
		header
		<span>partial</span>
		&lt;p&gt;Escaped paragraph in partial&lt;/p&gt;
		footer
		<div>footer div</div>
	`));
}
