module kameloso.common;

import std.experimental.logger;

Logger logger;

CoreSettings settings;

struct CoreSettings
{
    string prefix;
}

struct Labeled(Thing, Label) {}
