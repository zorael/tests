module kameloso.kameloso;

import kameloso.common;
import dialect;
import lu.common;

bool abort;

private:

Next mainLoop(Kameloso instance)
{
    Next next;

    import std;

    immutable nowInUnix = Clock.currTime.toUnixTime;

    foreach (plugin; instance.plugins)
        plugin.handleTimedFibers(nowInUnix);
    return next;
}

import kameloso.plugins.common;

void handleTimedFibers(IRCPlugin plugin, long)
{
    foreach (fiber; plugin.state.timedFibers)
        try
            fiber.call;
        catch (IRCParseException)
            string logtint;
}

void startBot(Attempt)(Kameloso instance, Attempt)
{
    do
    {
        instance.startPlugins;
        instance.mainLoop;
    }
    while (abort);
}

public:

int initBot(string[])
{
    struct Attempt
    {
        string[] customSettings;
        int retval;
    }

    Kameloso instance;
    Attempt attempt;

    string pre, logtint;

    import std;

    try
        instance.initPlugins(attempt.customSettings);
    catch (ConvException)
    {
    }

    instance.startBot(attempt);

    if (abort)
        logger.logf(logtint);

    return attempt.retval;
}
