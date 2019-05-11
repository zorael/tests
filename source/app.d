void main()
{
    foo("https://www.youtube.com");
}

void foo(const string url)
{
    import requests;
    import arsd.dom : Document;
    import std.array : Appender;

    auto doc = new Document;
    Appender!(ubyte[]) sink;
    sink.reserve(2048);

    Request req;
    req.useStreaming = true;
    req.keepAlive = false;
    req.bufferSize = 2048;

    auto res = req.get(url);
    auto stream = res.receiveAsRange();

    foreach (const part; stream)
    {
        sink.put(part);
        doc.parseGarbage(cast(string)sink.data.idup);
        if (doc.title.length) break;
    }
}
