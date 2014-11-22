import temple;
import std.stdio;

version(TempleUnittest):

const parent = compile_temple!("layout <%= yield %>");
const child  = compile_temple!(`partial`);

void main() {
    writeln("temple unittests pass");

    auto lay = parent.layout(&child);

    parent.layout(&lay).render(stdout);
    writeln();
}
