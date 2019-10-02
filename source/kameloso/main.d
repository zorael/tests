module kameloso.main;

import kameloso.plugins.common;
import lu.common;


private:

Next mainLoop(Kameloso instance)
{
    Next next;

    foreach (plugin; instance.plugins)
    {
        plugin.handleTimedFibers();
    }

    return next;
}


void handleTimedFibers(IRCPlugin plugin)
{
    foreach (fiber; plugin.state.timedFibers)
    {
        fiber.call();
    }
}


void startBot(Kameloso instance)
{
    instance.startPlugins();
    instance.mainLoop();
}

public:


int main()
{
    Kameloso instance;
    instance.initPlugins();
    instance.startBot();

    return 0;
}


struct Kameloso
{
    IRCPlugin[] plugins;

    void initPlugins()
    {
        import kameloso.plugins.connect : ConnectService;

        IRCPluginState state;
        plugins ~= new ConnectService(state);
    }

    void startPlugins()
    {
        foreach (plugin; plugins)
        {
            plugin.start();
        }
    }
}
