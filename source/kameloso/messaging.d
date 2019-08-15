module kameloso.messaging;

import kameloso.irc.defs;
import kameloso.plugins.common;
import std : Tid, send;

void query(IRCPluginState state, string, string)
{
    IRCEvent event;
    state.mainThread.send(event);
}
