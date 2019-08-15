module kameloso.irc.common;

import kameloso.irc.defs;

enum IRCControlCharacter
{
    bold
}

struct IRCClient
{
    string nickname;
    string user;
    string ident;
    string realName;
    string quitReason;
    string account;
    string password;
    string pass;
    string[] admins;
    string[] homes;
    string[] channels;
    IRCServer server;
    string origNickname;
    string modes;
}
