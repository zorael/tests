module kameloso.main;

import kameloso.plugins.common;
import lu.common;


void main()
{
    Kameloso instance;

    instance.initPlugins();
    instance.startPlugins();
    instance.mainLoop();
}


void mainLoop(Kameloso instance)
{
    foreach (plugin; instance.plugins)
    {
        foreach (fiber; plugin.state.timedFibers)
        {
            fiber.call();
        }
    }
}


struct Kameloso
{
    IRCPlugin[] plugins;

    void initPlugins()
    {
        import kameloso.plugins.connect : ConnectService;
        plugins ~= new ConnectService;
    }

    void startPlugins()
    {
        foreach (plugin; plugins)
        {
            plugin.start();
        }
    }
}
