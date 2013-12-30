module temple.output_stream;

version(Have_vibed)
{
	public import vibe.core.stream : OutputStream;
}
else
{
	// vibe.d OutputStream compatibility

	interface OutputStream {
		/** Writes an array of bytes to the stream.
		*/
		void write(in ubyte[] bytes);

		/** Writes an array of chars to the stream.
		*/
		final void write(in char[] bytes)
		{
			write(cast(const(ubyte)[])bytes);
		}

		/** These methods provide an output range interface.

			Note that these functions do not flush the output stream for performance reasons. flush()
			needs to be called manually afterwards.

			See_Also: $(LINK http://dlang.org/phobos/std_range.html#isOutputRange)
		*/
		final void put(ubyte elem) { write((&elem)[0 .. 1]); }
		/// ditto
		final void put(in ubyte[] elems) { write(elems); }
		/// ditto
		final void put(char elem) { write((&elem)[0 .. 1]); }
		/// ditto
		final void put(in char[] elems) { write(elems); }
		/// ditto
		final void put(dchar elem) { import std.utf; char[4] chars; encode(chars, elem); put(chars); }
		/// ditto
		final void put(in dchar[] elems) { foreach( ch; elems ) put(ch); }
	}
}