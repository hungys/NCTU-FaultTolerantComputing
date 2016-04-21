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
        end
        listen(upper, sl, delivered)
    end

    def on_send(sl, dest, mid, msg) do
        send sl, {:send, dest, mid, msg}
    end

    def on_deliver(upper, delivered, src, mid, msg) do
        if MapSet.member?(delivered, {src, mid, msg}) == :false do
            delivered = MapSet.put(delivered, {src, mid, msg})
            send upper, {:deliver, src, mid, msg}
        end
        delivered
    end
end
