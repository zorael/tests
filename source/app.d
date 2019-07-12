void main() {}

unittest
{
    import std.array : Appender;
    Appender!string sink;
    assert(sink.data);
}
