defmodule StubbornLink do
    @timeout 10000

    def init(name, upper) do
        fl = spawn(FairlossLink, :init, [name, self])
        spawn(StubbornLink, :starttimer, [self])
        listen(upper, fl, Map.new)
    end

    def listen(upper, fl, sent) do
        receive do
            {:send, dest, mid, msg} ->
                sent = on_send(fl, sent, dest, mid, msg)
            {:deliver, src, mid, msg} ->
                on_deliver(upper, src, mid, msg)
                send_ack(fl, src, mid)
            {:ack, _, mid} ->
                sent = Map.delete(sent, mid)
            {:link, name} -> send fl, {:link, name}
            {:unlink, name} -> send fl, {:unlink, name}
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
        Map.put(sent, mid, {dest, mid, msg})
    end

    def on_deliver(upper, src, mid, msg) do
        send upper, {:deliver, src, mid, msg}
    end

    def on_timeout(fl, sent) do
        Enum.each(Map.values(sent), fn(s) -> send fl, Tuple.insert_at(s, 0, :send) end)
    end

    def send_ack(fl, dest, mid) do
        send fl, {:send, dest, mid, :ack}
    end
end
