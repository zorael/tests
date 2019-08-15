module kameloso.irc.colours;

import kameloso.irc.common;

string ircBold(string word)
{
    return IRCControlCharacter.bold ~ word ~ IRCControlCharacter.bold;
}
