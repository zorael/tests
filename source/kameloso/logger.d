/++
 +  Contains the custom `KamelosoLogger` class, used to print timestamped and
 +  (optionally) coloured logging messages.
 +
 +  This is merely a subclass of `std.experimental.logger.Logger` that formats
 +  its arguments differently, implying the log level by way of colours.
 +
 +  Example:
 +  ---
 +  Logger logger = new KamelosoLogger;
 +
 +  logger.log("This is LogLevel.log");
 +  logger.info("LogLevel.info");
 +  logger.warn(".warn");
 +  logger.error(".error");
 +  logger.trace(".trace");
 +  //logger.fatal("This will crash the program.");
 +  ---
 +/
module kameloso.logger;

import std.experimental.logger : Logger;
import std.range.primitives : isOutputRange;

@safe:

/+
    Build tint colours at compile time, saving the need to compute them during
    runtime. It's a trade-off.
 +/
version = CtTints;


// KamelosoLogger
/++
 +  Modified `std.experimental.logger.Logger` to print timestamped and coloured logging messages.
 +
 +  It is thread-local so instantiate more if you're threading.
 +
 +  See the documentation for `std.experimental.logger.Logger`.
 +/
final class KamelosoLogger : Logger
{
@safe:
    import std.concurrency : Tid;
    import std.datetime.systime : SysTime;
    import std.experimental.logger : LogLevel;
    import std.stdio : stdout;

    version(Colours)
    {
        import kameloso.constants : DefaultColours;
        import kameloso.terminal : TerminalForeground, TerminalReset, colourWith, colour;

        alias logcoloursBright = DefaultColours.logcoloursBright;
        alias logcoloursDark = DefaultColours.logcoloursDark;
    }

    bool monochrome;  /// Whether to use colours or not in logger output.
    bool brightTerminal;   /// Whether or not to use colours for a bright background.
    bool flush;  /// Whether or not we should flush stdout after finishing writing to it.

    /// Create a new `KamelosoLogger` with the passed settings.
    this(LogLevel lv = LogLevel.all, bool monochrome = false,
        bool brightTerminal = false, bool flush = false)
    {
        this.monochrome = monochrome;
        this.brightTerminal = brightTerminal;
        this.flush = flush;
        super(lv);
    }

    // tint
    /++
     +  Returns the corresponding `kameloso.terminal.TerminalForeground` for the
     +  supplied `std.experimental.logger.LogLevel`,
     +  taking into account whether the terminal is said to be bright or not.
     +
     +  This is merely a convenient wrapping for `logcoloursBright` and
     +  `logcoloursDark`.
     +
     +  Example:
     +  ---
     +  TerminalForeground errtint = KamelosoLogger.tint(LogLevel.error, false);  // false means dark terminal
     +  immutable errtintString = errtint.colour;
     +  ---
     +
     +  Params:
     +      level = The `std.experimental.logger.LogLevel` of the colour we want to scry.
     +      bright = Whether the colour should be for a bright terminal
     +          background or a dark one.
     +
     +  Returns:
     +      A `kameloso.terminal.TerminalForeground` of the right colour. Use with
     +      `kameloso.terminal.colour` to get a string.
     +/
    version(Colours)
    static auto tint(const LogLevel level, const bool bright)
    {
        return bright ? logcoloursBright[level] : logcoloursDark[level];
    }

    ///
    version(Colours)
    unittest
    {
        import std.range : only;

        foreach (immutable logLevel; only(LogLevel.all, LogLevel.info, LogLevel.warning, LogLevel.fatal))
        {
            import std.format : format;

            immutable tintBright = tint(logLevel, true);
            immutable tintBrightTable = logcoloursBright[logLevel];
            assert((tintBright == tintBrightTable), "%s != %s".format(tintBright, tintBrightTable));

            immutable tintDark = tint(logLevel, false);
            immutable tintDarkTable = logcoloursDark[logLevel];
            assert((tintDark == tintDarkTable), "%s != %s".format(tintDark, tintDarkTable));
        }
    }

    // tintImpl
    /++
     +  Template for returning tints based on the settings of the `this`
     +  `KamelosoLogger`.
     +
     +  This saves us having to pass the brightness setting, and allows for
     +  making easy aliases for the log level.
     +
     +  Params:
     +      level = Compile-time `std.experimental.logger.LogLevel`.
     +
     +  Returns:
     +      A tint string.
     +/
    version(Colours)
    private string tintImpl(LogLevel level)() const @property
    {
        version(CtTints)
        {
            if (brightTerminal)
            {
                enum ctTint = tint(level, true).colour;
                return ctTint;
            }
            else
            {
                enum ctTint = tint(level, false).colour;
                return ctTint;
            }
        }
        else
        {
            return tint(level, brightTerminal).colour;
        }
    }

    pragma(inline)
    version(Colours)
    {
        /// Provides easy way to get a log tint.
        auto logtint() const @property { return tintImpl!(LogLevel.all); }

        /// Provides easy way to get an info tint.
        auto infotint() const @property { return tintImpl!(LogLevel.info); }

        /// Provides easy way to get a warning tint.
        auto warningtint() const @property { return tintImpl!(LogLevel.warning); }

        /// Provides easy way to get an error tint.
        auto errortint() const @property { return tintImpl!(LogLevel.error); }

        /// Provides easy way to get a fatal tint.
        auto fataltint() const @property { return tintImpl!(LogLevel.fatal); }
    }

    /++
     +  This override is needed or it won't compile.
     +
     +  Params:
     +      payload = Message payload to write.
     +/
    override void writeLogMsg(ref LogEntry payload) pure nothrow const @nogc {}

    /// Outputs the head of a logger message.
    protected void beginLogMsg(Sink)(auto ref Sink sink,
        string file, int line, string funcName,
        string prettyFuncName, string moduleName, LogLevel logLevel,
        Tid threadId, SysTime timestamp, Logger logger) const
    if (isOutputRange!(Sink, char[]))
    {
        import std.datetime : DateTime;

        static if (!__traits(hasMember, Sink, "put")) import std.range.primitives : put;

        version(Colours)
        {
            if (!monochrome)
            {
                sink.colourWith(brightTerminal ? TerminalForeground.black : TerminalForeground.white);
            }
        }

        sink.put('[');
        sink.put((cast(DateTime)timestamp).timeOfDay.toString());
        sink.put("] ");

        if (monochrome) return;

        version(Colours)
        {
            sink.colourWith(brightTerminal ? logcoloursBright[logLevel] : logcoloursDark[logLevel]);
        }
    }

    /// ditto
    override protected void beginLogMsg(string file, int line, string funcName,
        string prettyFuncName, string moduleName, LogLevel logLevel,
        Tid threadId, SysTime timestamp, Logger logger) @trusted const
    {
        return beginLogMsg(stdout.lockingTextWriter, file, line, funcName,
            prettyFuncName, moduleName, logLevel, threadId, timestamp, logger);
    }

    /// Outputs the message part of a logger message; the content.
    protected void logMsgPart(Sink)(auto ref Sink sink, const(char)[] msg) const
    if (isOutputRange!(Sink, char[]))
    {
        static if (!__traits(hasMember, Sink, "put")) import std.range.primitives : put;

        sink.put(msg);
    }

    /// ditto
    override protected void logMsgPart(scope const(char)[] msg) @trusted const
    {
        if (!msg.length) return;

        return logMsgPart(stdout.lockingTextWriter, msg);
    }

    /// Outputs the tail of a logger message.
    protected void finishLogMsg(Sink)(auto ref Sink sink) const
    if (isOutputRange!(Sink, char[]))
    {
        static if (!__traits(hasMember, Sink, "put")) import std.range.primitives : put;

        version(Colours)
        {
            if (!monochrome)
            {
                // Reset.blink in case a fatal message was thrown
                sink.colourWith(TerminalForeground.default_, TerminalReset.blink);
            }
        }

        static if (__traits(hasMember, Sink, "data"))
        {
            writeln(sink.data);
            sink.clear();
        }
        else
        {
            sink.put('\n');
        }
    }

    /// ditto
    override protected void finishLogMsg() @trusted const
    {
        finishLogMsg(stdout.lockingTextWriter);
        if (flush) stdout.flush();
    }
}

///
unittest
{
    import std.experimental.logger : LogLevel;

    Logger log_ = new KamelosoLogger(LogLevel.all, true, false);

    log_.log("log: log");
    log_.info("log: info");
    log_.warning("log: warning");
    log_.error("log: error");
    // log_.fatal("log: FATAL");  // crashes the program
    log_.trace("log: trace");

    version(Colours)
    {
        log_ = new KamelosoLogger(LogLevel.all, false, true);

        log_.log("log: log");
        log_.info("log: info");
        log_.warning("log: warning");
        log_.error("log: error");
        // log_.fatal("log: FATAL");
        log_.trace("log: trace");

        log_ = new KamelosoLogger(LogLevel.all, false, false);

        log_.log("log: log");
        log_.info("log: info");
        log_.warning("log: warning");
        log_.error("log: error");
        // log_.fatal("log: FATAL");
        log_.trace("log: trace");
    }
}
