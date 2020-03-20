/++
 +  Functions related to (formatting and) printing structs and classes to the
 +  local terminal, listing each member variable and their contents in an
 +  easy-to-visually-parse way.
 +
 +  Example:
 +
 +  `printObjects(client, bot, settings);`
 +  ---
-- IRCClient
   string nickname               "kameloso"(8)
   string user                   "kameloso"(8)
   string ident                  "NaN"(3)
   string realName               "kameloso IRC bot"(16)

-- IRCBot
   string account                "kameloso"(8)
 string[] admins                ["zorael"](1)
 string[] homes                 ["#flerrp"](1)
 string[] channels              ["#d"](1)

-- IRCServer
   string address                "irc.freenode.net"(16)
   ushort port                    6667
 +  ---
 +
 +  Distance between types, member names and member values are deduced automatically
 +  based on how long they are (in terms of characters). If it doesn't line up,
 +  its a bug.
 +/
module kameloso.printing;

private:

import std.range.primitives : isOutputRange;
import std.typecons : Flag, No, Yes;

public:


// printObjects
/++
 +  Prints out struct objects, with all their printable members with all their
 +  printable values.
 +
 +  This is not only convenient for debugging but also usable to print out
 +  current settings and state, where such is kept in structs.
 +
 +  Example:
 +  ---
 +  struct Foo
 +  {
 +      int foo;
 +      string bar;
 +      float f;
 +      double d;
 +  }
 +
 +  Foo foo, bar;
 +  printObjects(foo, bar);
 +  ---
 +
 +  Params:
 +      printAll = Whether or not to also display members marked as
 +          `lu.uda.Unconfigurable`, usually transitive information that
 +          doesn't carry between program runs.
 +      widthArg = The width with which to pad output columns.
 +      things = Variadic list of struct objects to enumerate.
 +/
void printObjects(Flag!"printAll" printAll = No.printAll, uint widthArg = 0, Things...)
    (auto ref Things things) @trusted
{
    import kameloso.common : settings;
    import std.stdio : stdout;

    // writeln trusts `lockingTextWriter` so we will too.

    bool printed;

    version(Colours)
    {
        if (!settings.monochrome)
        {
            formatObjects!(printAll, Yes.coloured, widthArg)(stdout.lockingTextWriter,
                settings.brightTerminal, things);
            printed = true;
        }
    }

    if (!printed)
    {
        // Brightness setting is irrelevant; pass false
        formatObjects!(printAll, No.coloured, widthArg)(stdout.lockingTextWriter, false, things);
    }

    if (settings.flush) stdout.flush();
}

alias printObject = printObjects;


// formatObjects
/++
 +  Formats a struct object, with all its printable members with all their
 +  printable values.
 +
 +  This is an implementation template and should not be called directly;
 +  instead use `printObject` and `printObjects`.
 +
 +  Example:
 +  ---
 +  struct Foo
 +  {
 +      int foo = 42;
 +      string bar = "arr matey";
 +      float f = 3.14f;
 +      double d = 9.99;
 +  }
 +
 +  Foo foo, bar;
 +  Appender!string sink;
 +
 +  sink.formatObjects!(Yes.coloured)(foo);
 +  sink.formatObjects!(No.coloured)(bar);
 +  writeln(sink.data);
 +  ---
 +
 +  Params:
 +      printAll = Whether or not to also display members marked as
 +          `lu.uda.Unconfigurable`, usually transitive information that
 +          doesn't carry between program runs.
 +      coloured = Whether to display in colours or not.
 +      widthArg = The width with which to pad output columns.
 +      sink = Output range to write to.
 +      bright = Whether or not to format for a bright terminal background.
 +      things = Variadic list of structs to enumerate and format.
 +/
void formatObjects(Flag!"printAll" printAll = No.printAll,
    Flag!"coloured" coloured = Yes.coloured, uint widthArg = 0, Sink, Things...)
    (auto ref Sink sink, const bool bright, auto ref Things things)
if (isOutputRange!(Sink, char[]))
{
    import std.algorithm.comparison : max;

    static if (!__traits(hasMember, Sink, "put")) import std.range.primitives : put;

    static if (coloured)
    {
        import kameloso.terminal : TerminalForeground, colour;
        alias F = TerminalForeground;
    }

    static if (__VERSION__ < 2076L)
    {
        // workaround formattedWrite taking sink by value pre 2.076
        sink.put(string.init);
    }

    enum minimumTypeWidth = 9;  // Current sweet spot, accommodates well for `string[]`
    enum minimumNameWidth = 24;  // Current minimum, TwitchBotSettings' "regularsAreWhitelisted"

    static if (printAll)
    {
        import kameloso.traits : longestUnconfigurableMemberName, longestUnconfigurableMemberTypeName;
        enum typewidth = max(minimumTypeWidth, (longestUnconfigurableMemberTypeName!Things.length + 1));
        enum initialWidth = !widthArg ? longestUnconfigurableMemberName!Things.length : widthArg;
    }
    else
    {
        import kameloso.traits : longestMemberName, longestMemberTypeName;
        enum typewidth = max(minimumTypeWidth, (longestMemberTypeName!Things.length + 1));
        enum initialWidth = !widthArg ? longestMemberName!Things.length : widthArg;
    }

    enum ptrdiff_t compensatedWidth = (typewidth > minimumTypeWidth) ?
        (initialWidth - typewidth + minimumTypeWidth) : initialWidth;
    enum ptrdiff_t namewidth = max(minimumNameWidth, compensatedWidth);

    foreach (immutable n, const ref thing; things)
    {
        import lu.string : stripSuffix;
        import std.format : formattedWrite;
        import std.traits : Unqual;

        alias Thing = Unqual!(typeof(thing));

        static if (coloured)
        {
            immutable titleCode = bright ? F.black : F.white;
            sink.formattedWrite("%s-- %s\n", titleCode.colour, Thing.stringof.stripSuffix("Settings"));
        }
        else
        {
            sink.formattedWrite("-- %s\n", Thing.stringof.stripSuffix("Settings"));
        }

        foreach (immutable i, member; thing.tupleof)
        {
            import lu.traits : isConfigurableVariable;
            import lu.uda : Hidden, Unconfigurable;
            import std.traits : hasUDA, isAssociativeArray, isType;

            enum shouldNormallyBePrinted = !__traits(isDeprecated, thing.tupleof[i]) &&
                !isType!member &&
                isConfigurableVariable!member &&
                !hasUDA!(thing.tupleof[i], Hidden) &&
                !hasUDA!(thing.tupleof[i], Unconfigurable);

            enum shouldMaybeBePrinted = printAll && !hasUDA!(thing.tupleof[i], Hidden);

            static if (shouldNormallyBePrinted || shouldMaybeBePrinted)
            {
                import lu.traits : isTrulyString;
                import std.traits : isArray;

                alias T = Unqual!(typeof(member));

                enum memberstring = __traits(identifier, thing.tupleof[i]);

                static if (isTrulyString!T)
                {
                    static if (coloured)
                    {
                        enum stringPattern = `%s%*s %s%-*s %s%s"%s"%s(%d)` ~ '\n';
                        immutable memberCode = bright ? F.black : F.white;
                        immutable valueCode = bright ? F.green : F.lightgreen;
                        immutable lengthCode = bright ? F.lightgrey : F.darkgrey;
                        immutable typeCode = bright ? F.lightcyan : F.cyan;

                        sink.formattedWrite(stringPattern,
                            typeCode.colour, typewidth, T.stringof,
                            memberCode.colour, (namewidth + 2), memberstring,
                            (member.length < 2) ? " " : string.init,
                            valueCode.colour, member,
                            lengthCode.colour, member.length);
                    }
                    else
                    {
                        enum stringPattern = `%*s %-*s %s"%s"(%d)` ~ '\n';
                        sink.formattedWrite(stringPattern, typewidth, T.stringof,
                            (namewidth + 2), memberstring,
                            (member.length < 2) ? " " : string.init,
                            member, member.length);
                    }
                }
                else static if (isArray!T || isAssociativeArray!T)
                {
                    import std.range.primitives : ElementEncodingType;

                    alias ElemType = Unqual!(ElementEncodingType!T);
                    enum elemIsCharacter = is(ElemType == char) || is(ElemType == dchar) || is(ElemType == wchar);

                    immutable thisWidth = member.length ? (namewidth + 2) : (namewidth + 4);

                    static if (coloured)
                    {
                        static if (elemIsCharacter)
                        {
                            enum arrayPattern = "%s%*s %s%-*s%s[%(%s, %)]%s(%d)\n";
                        }
                        else
                        {
                            enum arrayPattern = "%s%*s %s%-*s%s%s%s(%d)\n";
                        }

                        immutable memberCode = bright ? F.black : F.white;
                        immutable valueCode = bright ? F.green : F.lightgreen;
                        immutable lengthCode = bright ? F.lightgrey : F.darkgrey;
                        immutable typeCode = bright ? F.lightcyan : F.cyan;

                        import lu.traits : UnqualArray;

                        sink.formattedWrite(arrayPattern,
                            typeCode.colour, typewidth, UnqualArray!T.stringof,
                            memberCode.colour, thisWidth, memberstring,
                            valueCode.colour, member,
                            lengthCode.colour, member.length);
                    }
                    else
                    {
                        static if (elemIsCharacter)
                        {
                            enum arrayPattern = "%*s %-*s[%(%s, %)](%d)\n";
                        }
                        else
                        {
                            enum arrayPattern = "%*s %-*s%s(%d)\n";
                        }

                        import lu.traits : UnqualArray;

                        sink.formattedWrite(arrayPattern,
                            typewidth, UnqualArray!T.stringof,
                            thisWidth, memberstring,
                            member,
                            member.length);
                    }
                }
                else static if (is(T == struct) || is(T == class))
                {
                    enum classOrStruct = is(T == struct) ? "struct" : "class";

                    immutable initText = (thing.tupleof[i] == Thing.init.tupleof[i]) ? " (init)" : string.init;

                    static if (coloured)
                    {
                        enum normalPattern = "%s%*s %s%-*s %s<%s>%s\n";
                        immutable memberCode = bright ? F.black : F.white;
                        immutable valueCode = bright ? F.green : F.lightgreen;
                        immutable typeCode = bright ? F.lightcyan : F.cyan;

                        sink.formattedWrite(normalPattern,
                            typeCode.colour, typewidth, T.stringof,
                            memberCode.colour, (namewidth + 2), memberstring,
                            valueCode.colour, classOrStruct, initText);
                    }
                    else
                    {
                        enum normalPattern = "%*s %-*s <%s>%s\n";
                        sink.formattedWrite(normalPattern, typewidth, T.stringof,
                            (namewidth + 2), memberstring, classOrStruct, initText);
                    }
                }
                else
                {
                    static if (coloured)
                    {
                        enum normalPattern = "%s%*s %s%-*s  %s%s\n";
                        immutable memberCode = bright ? F.black : F.white;
                        immutable valueCode = bright ? F.green : F.lightgreen;
                        immutable typeCode = bright ? F.lightcyan : F.cyan;

                        sink.formattedWrite(normalPattern,
                            typeCode.colour, typewidth, T.stringof,
                            memberCode.colour, (namewidth + 2), memberstring,
                            valueCode.colour, member);
                    }
                    else
                    {
                        enum normalPattern = "%*s %-*s  %s\n";
                        sink.formattedWrite(normalPattern, typewidth, T.stringof,
                            (namewidth + 2), memberstring, member);
                    }
                }
            }
        }

        static if (coloured)
        {
            enum defaultColour = F.default_.colour;
            sink.put(defaultColour);
        }

        static if ((n+1 < things.length) || !__traits(hasMember, Sink, "data"))
        {
            // Not an Appender, make sure it has a final linebreak to be consistent
            // with Appender writeln
            sink.put('\n');
        }
    }
}

///
@system unittest
{
    import lu.string : contains;
    import std.array : Appender;

    struct Struct
    {
        string members;
        int asdf;
    }

    // Monochrome

    struct StructName
    {
        Struct struct_;
        int i = 12_345;
        string s = "foo";
        string p = "!";
        string p2;
        bool b = true;
        float f = 3.14f;
        double d = 99.9;
        const(char)[] c = [ 'a', 'b', 'c' ];
        const(char)[] emptyC;
        string[] dynA = [ "foo", "bar", "baz" ];
        int[] iA = [ 1, 2, 3, 4 ];
        const(char)[char] cC;
    }

    StructName s;
    s.cC = [ 'a':'a', 'b':'b' ];
    assert('a' in s.cC);
    assert('b' in s.cC);
    Appender!(char[]) sink;

    sink.reserve(512);  // ~323
    sink.formatObjects!(No.printAll, No.coloured)(false, s);

    enum structNameSerialised =
`-- StructName
     Struct struct_                    <struct> (init)
        int i                           12345
     string s                          "foo"(3)
     string p                           "!"(1)
     string p2                          ""(0)
       bool b                           true
      float f                           3.14
     double d                           99.9
     char[] c                         ['a', 'b', 'c'](3)
     char[] emptyC                      [](0)
   string[] dynA                      ["foo", "bar", "baz"](3)
      int[] iA                        [1, 2, 3, 4](4)
 char[char] cC                        ['b':'b', 'a':'a'](2)
`;
    assert((sink.data == structNameSerialised), "\n" ~ sink.data);

    // Adding Settings does nothing
    alias StructNameSettings = StructName;
    StructNameSettings so = s;
    sink.clear();
    sink.formatObjects!(No.printAll, No.coloured)(false, so);

    assert((sink.data == structNameSerialised), "\n" ~ sink.data);

    // Two at a time
    struct Struct1
    {
        string members;
        int asdf;
    }

    struct Struct2
    {
        string mumburs;
        int fdsa;
    }

    Struct1 st1;
    Struct2 st2;

    st1.members = "harbl";
    st1.asdf = 42;
    st2.mumburs = "hirrs";
    st2.fdsa = -1;

    sink.clear();
    sink.formatObjects!(No.printAll, No.coloured)(false, st1, st2);
    enum st1st2Formatted =
`-- Struct1
   string members                    "harbl"(5)
      int asdf                        42

-- Struct2
   string mumburs                    "hirrs"(5)
      int fdsa                        -1
`;
    assert((sink.data == st1st2Formatted), '\n' ~ sink.data);

    // Colour
    struct StructName2
    {
        int int_ = 12_345;
        string string_ = "foo";
        bool bool_ = true;
        float float_ = 3.14f;
        double double_ = 99.9;
    }

    version(Colours)
    {
        StructName2 s2;

        sink.clear();
        sink.reserve(256);  // ~239
        sink.formatObjects!(No.printAll, Yes.coloured)(false, s2);

        assert((sink.data.length > 12), "Empty sink after coloured fill");

        assert(sink.data.contains("-- StructName"));
        assert(sink.data.contains("int_"));
        assert(sink.data.contains("12345"));

        assert(sink.data.contains("string_"));
        assert(sink.data.contains(`"foo"`));

        assert(sink.data.contains("bool_"));
        assert(sink.data.contains("true"));

        assert(sink.data.contains("float_"));
        assert(sink.data.contains("3.14"));

        assert(sink.data.contains("double_"));
        assert(sink.data.contains("99.9"));

        // Adding Settings does nothing
        alias StructName2Settings = StructName2;
        immutable sinkCopy = sink.data.idup;
        StructName2Settings s2o;

        sink.clear();
        sink.formatObjects!(No.printAll, Yes.coloured)(false, s2o);
        assert((sink.data == sinkCopy), sink.data);
    }
}


// formatObjects
/++
 +  A `string`-returning variant of `formatObjects` that doesn't take an input range.
 +
 +  This is useful when you just want the object(s) formatted without having to
 +  pass it a sink.
 +
 +  Example:
 +  ---
 +  struct Foo
 +  {
 +      int foo = 42;
 +      string bar = "arr matey";
 +      float f = 3.14f;
 +      double d = 9.99;
 +  }
 +
 +  Foo foo, bar;
 +
 +  writeln(formatObjects!(Yes.coloured)(foo));
 +  writeln(formatObjects!(No.coloured)(bar));
 +  ---
 +
 +  Params:
 +      printAll = Whether or not to also display members marked as
 +          `lu.uda.Unconfigurable`, usually transitive information that
 +          doesn't carry between program runs.
 +      coloured = Whether to display in colours or not.
 +      widthArg = The width with which to pad output columns.
 +      bright = Whether or not to format for a bright terminal background.
 +      things = Variadic list of structs to enumerate and format.
 +
 +  Returns:
 +      String with the object formatted, as per the passed arguments.
 +/
string formatObjects(Flag!"printAll" printAll = No.printAll,
    Flag!"coloured" coloured = Yes.coloured, uint widthArg = 0, Things...)
    (const bool bright, Things things)
if ((Things.length > 0) && !isOutputRange!(Things[0], char[]))
{
    import std.array : Appender;

    Appender!string sink;
    sink.reserve(1024);

    sink.formatObjects!(printAll, coloured, widthArg)(bright, things);
    return sink.data;
}

///
unittest
{
    // Rely on the main unit tests of the output range version of formatObjects

    struct Struct
    {
        string members;
        int asdf;
    }

    Struct s;
    s.members = "foo";
    s.asdf = 42;

    immutable formatted = formatObjects!(No.printAll, No.coloured)(false, s);
    assert((formatted ==
`-- Struct
   string members                    "foo"(3)
      int asdf                        42
`), '\n' ~ formatted);
}
