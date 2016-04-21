defmodule StubbornLink do
    @timeout 10000

    def init(name, upper) do
        fl = spawn(FairlossLink, :init, [name, self])
        spawn(StubbornLink, :starttimer, [self])
        listen(upper, fl, MapSet.new)
    end

    def listen(upper, fl, sent) do
        receive do
            {:send, dest, mid, msg} ->
                sent = on_send(fl, sent, dest, mid, msg)
            {:deliver, src, mid, msg} -> on_deliver(upper, src, mid, msg)
            :timeout -> on_timeout(fl, sent)
        end
        listen(upper, fl, sent)
    end

    def starttimer(sl) do
        :timer.sleep(@timeout)
        send sl, :timeout
        starttimer(sl)
    end

    def on_send(fl, sent, dest, mid, msg) do
        send fl, {:send, dest, mid, msg}
        MapSet.put(sent, {:send, dest, mid, msg})
    end

    def on_deliver(upper, src, mid, msg) do
        send upper, {:deliver, src, mid, msg}
    end

    def on_timeout(fl, sent) do
        Enum.each(sent, fn(s) -> send fl, s end)
    end
end
