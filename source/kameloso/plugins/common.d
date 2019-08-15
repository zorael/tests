module kameloso.plugins.common;

import kameloso.irc.common;
import kameloso.irc.defs;

interface IRCPlugin
{
    string name() const;
    Description[string] commands() const;
}

class TriggerRequest {}

struct IRCPluginState
{
    import kameloso.common;
    import core.thread;
    import std;

    IRCClient client;
    Tid mainThread;
    IRCUser[] users;
    IRCChannel[] channels;
    TriggerRequest[] triggerRequestQueue;
    Fiber[] awaitingFibers;
    Labeled!(Fiber, long)[] timedFibers;
    long nextPeriodical;
}

struct Description
{
    string syntax;
}

template IRCPluginImpl()
{
    IRCPluginState privateState;

    this(IRCPluginState state)
    {
        privateState = state;
    }

    inout(IRCPluginState) state() inout @nogc
    {
        return this.privateState;
    }
}
