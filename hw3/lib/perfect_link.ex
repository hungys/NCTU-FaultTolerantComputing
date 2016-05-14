defmodule PerfectLink do
    def init(name, upper) do
        sl = spawn(StubbornLink, :init, [name, self])
        listen(upper, sl, MapSet.new)
    end

    def listen(upper, sl, delivered) do
        receive do
            {:send, dest, mid, msg} -> on_send(sl, dest, mid, msg)
            {:deliver, src, mid, msg} ->
                delivered = on_deliver(upper, delivered, src, mid, msg)
            {:link, name} -> send sl, {:link, name}
            {:unlink, name} -> send sl, {:unlink, name}
        end
        listen(upper, sl, delivered)
    end

    def on_send(sl, dest, mid, msg) do
        send sl, {:send, dest, mid, msg}
    end

    def on_deliver(upper, delivered, src, mid, msg) do
        if MapSet.member?(delivered, mid) == :false do
            delivered = MapSet.put(delivered, mid)
            send upper, {:deliver, src, mid, msg}
        end
        delivered
    end
end
