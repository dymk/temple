module temple.tests.vibe;

version(Have_vibe_d) {}
else {
	static assert(false, "temple.tests.vibed must be compiled with vibe.d");
}

private {
	import temple.tests.common;
	import vibe.http.server;
}

private final class DummyHttpServerResponse : HttpServerResponse {
private:
	AppenderOutputStream appender;

public:
	this() {
		appender = new AppenderOutputStream();
	}

	override OutputStream bodyWriter() @property {
		return appender;
	}

	string rendered() {
		return appender.data();
	}
}

unittest {
	HttpServerResponse resp = new DummyHttpServerResponse();
}
