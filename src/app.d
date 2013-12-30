import temple.temple;

version(unittest) {
	pragma(msg, "Compiling templ with tests...");
} else {
	static assert(false, "Please build with -unittest when compiling directly");
}
void main() {}
