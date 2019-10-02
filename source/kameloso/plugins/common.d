
module kameloso.plugins.common;

import dialect;

import core.thread ;
interface IRCPlugin
{
    
    ref inout(IRCPluginState) state() inout @nogc ;

    
    void start() ;

}




struct IRCPluginState
{
    import lu.common ;
    import std;

    
    Fiber[][EnumMembers!(IRCEvent.Type).length] awaitingFibers;

    
    Labeled!(Fiber, long)[] timedFibers;

}




template IRCPluginImpl()
{
IRCPluginState privateState;

this(IRCPluginState )     {
    }


void start()     {
            import lu.traits ;
static if (TakesParams!(.start, typeof(this)))
                .start(this);
    }


ref inout(IRCPluginState) state() inout @nogc     {
        return this.privateState;
    }


}

void delayFiber(IRCPlugin plugin, Fiber fiber, long )
{
    import lu.common ;
    import std;

    immutable time = Clock.currTime.toUnixTime ;
    plugin.state.timedFibers ~= labeled(fiber, time);
}




