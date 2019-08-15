module kameloso.irc.defs;

struct IRCEvent
{
    string raw;
    IRCUser sender;
    string channel;
    IRCUser target;
    string content;
    string aux;
    string tags;
    long time;
}

struct IRCServer
{
    enum Daemon
    {
        hybrid
    }

    string address;
    Daemon daemon;
    string network;
    string daemonstring;
    string resolvedAddress;
    string aModes;
    string bModes;
    string cModes;
    string dModes;
    char[] prefixchars;
    string prefixes;
    string extbanTypes;
}

struct IRCUser
{
    enum Class
    {
        unset
    }

    string nickname;
    string alias_;
    string ident;
    string address;
    string account;
    long lastWhois;
    Class class_;
}

struct IRCChannel {}
