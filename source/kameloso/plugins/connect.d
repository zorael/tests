module kameloso.plugins.connect;

import kameloso.plugins.common;
import kameloso.messaging;

void register(ConnectService service)
{
    enum secsToWaitForCAP = 0;

    void dg()
    {
        service.negotiateNick;
    }

    import core.thread;

    Fiber fiber = new Fiber(&dg);
    service.delayFiber(fiber, secsToWaitForCAP);
}

void negotiateNick(ConnectService service)
{
    raw(service.state, "USER %s 8 * :%s");
}

void start(ConnectService service)
{
    register(service);
}

class ConnectService : IRCPlugin
{
    mixin IRCPluginImpl;
}
