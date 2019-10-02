module kameloso.plugins.common;

import dialect;
import core.thread : Fiber;


interface IRCPlugin
{
    ref inout(IRCPluginState) state() inout @nogc;
    void start();
}


struct IRCPluginState
{
    import lu.common : Labeled;
    import std.traits : EnumMembers;

    Fiber[][EnumMembers!(IRCEvent.Type).length] awaitingFibers;
    Labeled!(Fiber, long)[] timedFibers;
}


mixin template IRCPluginImpl()
{
    IRCPluginState privateState;

    this() {}

    void start()
    {
        .start(this);
    }

    ref inout(IRCPluginState) state() inout @nogc
    {
        return this.privateState;
    }
}


void delayFiber(IRCPlugin plugin, Fiber fiber, long)
{
    import lu.common : labeled;
    import std.datetime.systime : Clock;

    immutable time = Clock.currTime.toUnixTime;
    plugin.state.timedFibers ~= labeled(fiber, time);
}
