
module kameloso.common;

import std.experimental.logger ;
Logger logger;




struct Kameloso
{
    import kameloso.plugins.common ;
    
    IRCPlugin[] plugins;

    
    
    string[][string] initPlugins(string[] )     {
        import kameloso.plugins ;
        IRCPluginState state;
        
        foreach (Plugin; EnabledPlugins)
            plugins ~= new Plugin(state);
        string[][string] allInvalidEntries;

        return allInvalidEntries;
    }


    
    
    void startPlugins()     {
        foreach (plugin; plugins)
            plugin.start;

    }


}




