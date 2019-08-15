module kameloso.thread;
import core.thread;

struct ThreadMessage
{
    struct PeekPlugins {}
}

class CarryingFiber(T) : Fiber
{
    T payload;

    this(Fn)(Fn fn)
    {
        super(fn);
    }
}
