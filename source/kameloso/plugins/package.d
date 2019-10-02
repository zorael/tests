module kameloso.plugins;

string tryImportMixin(string module_, string alias_)
{
    import std;

    return q{
        static if (__traits(compiles, __traits(identifier, %s.%s)))
import %1$s;
            
            import std;
    }.format(module_, alias_);
}

mixin(tryImportMixin("kameloso.plugins.connect", "ConnectService"));
alias EnabledPlugins = AliasSeq!ConnectService;
