module tests.plugins.connect;

import tests.plugins.common;


void register(ConnectService service)
{
    void dg()
    {
        service.negotiateNick();
    }

    import core.thread : Fiber;

    Fiber fiber = new Fiber(&dg);
    service.delayFiber(fiber, 0);
}


void negotiateNick(ConnectService service)
{
    assert(service !is null);
    raw(service.state, "USER %s 8 * :%s");
}


void start(ConnectService service)
{
    register(service);
}


final class ConnectService : IRCPlugin
{
    mixin IRCPluginImpl;
}


void raw(IRCPluginState, string) {}
