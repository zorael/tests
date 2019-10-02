module tests.main;

import tests.plugins.common;


void main()
{
    Tests instance;

    instance.initPlugins();
    instance.startPlugins();
    instance.mainLoop();
}


void mainLoop(Tests instance)
{
    foreach (plugin; instance.plugins)
    {
        foreach (fiber; plugin.state.timedFibers)
        {
            fiber.call();
        }
    }
}


struct Tests
{
    IRCPlugin[] plugins;

    void initPlugins()
    {
        import tests.plugins.connect : ConnectService;
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
