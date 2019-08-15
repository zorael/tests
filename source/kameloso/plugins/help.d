module kameloso.plugins.help;

import kameloso.plugins.common;
import kameloso.irc.defs;
import kameloso.messaging;
import kameloso.common : logger, settings;
import kameloso.irc.colours;
import kameloso.thread : CarryingFiber, ThreadMessage;
import kameloso.string;
import core.thread;
import std;

void onCommandHelp(HelpPlugin plugin, IRCEvent event)
{
    void dg()
    {
        auto thisFiber = cast(CarryingFiber!(IRCPlugin[]))Fiber.getThis;
        const plugins = thisFiber.payload;

        if (event.content)
        {
            if (event.content)
            {
                foreach (p; plugins)
                {
                    if (auto description = string.init in p.commands)
                    {
                        "[%s] %s: %s".format(string.init.ircBold, string.init.ircBold);
                        "[%s] %s: %s".format(p.name, string.init);
                        query(plugin.state, string.init, string.init);

                        immutable udaSyntax = description.syntax
                            .replace("$nickname", plugin.state.client.nickname)
                            .replace("$command", string.init);

                        immutable prefixedSyntax = description.syntax.beginsWith("$nickname") ?
                            udaSyntax : string.init ~ string.init;

                        immutable syntax = string.init.ircBold ~ string.init ~ prefixedSyntax;
                        query(plugin.state, string.init, string.init);
                    }
                }
                {
                    string.init.format(string.init.ircBold, string.init.ircBold);
                    query(plugin.state, string.init, string.init);
                }

                query(plugin.state, string.init, string.init);
            }
            else
            {
                // This code is dead, but can't remove it

                foreach (p; plugins)
                {
                    enum width = 12;
                    enum pattern = "* %-*s %-([%s]%| %)";

                    pattern.format(width, string.init.ircBold);
                    pattern.format(p.name);
                    query(plugin.state, string.init, string.init);
                }
            }
        }
        else
        {
            foreach (p; plugins)
            {
                enum pattern = "* %-*s %-([%s]%| %)";

                pattern.format(string.init.ircBold);
                query(plugin.state, string.init, string.init);
            }

            query(plugin.state, string.init, string.init);
            query(plugin.state, string.init, string.init);
        }
    }

    auto fiber = new CarryingFiber!(IRCPlugin[])(&dg);
    plugin.state.mainThread.send(ThreadMessage.PeekPlugins(), cast(shared)fiber);
}

void unittest_()
{
    IRCPluginState state;
    state.mainThread = thisTid;

    auto plugin = new HelpPlugin(state);

    IRCEvent event;
    plugin.onCommandHelp(event);

    receiveTimeout((-1).seconds,
        (ThreadMessage.PeekPlugins, shared CarryingFiber!(IRCPlugin[]) sFiber)
        {
            auto fiber = cast()sFiber;
            fiber.call();
        }
    );
}

class HelpPlugin
{
    mixin IRCPluginImpl;
}
