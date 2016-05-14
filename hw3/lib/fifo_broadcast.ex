defmodule FIFOBroadcast do
    def init(name, upper) do
        rb = spawn(ReliableBroadcast, :init, [name, self])
        listen(upper, rb, 0, MapSet.new, Map.new)
    end

    def listen(upper, rb, seqno, msgbag, next) do
        receive do
            {:broadcast, bid, msg} ->
                seqno = seqno + 1
                on_broadcast(rb, bid, seqno, msg)
            {:deliver, bid, bsrc, msg} ->
                {msgbag, next} = on_deliver(upper, msgbag, next, bid, bsrc, msg)
            {:add_neighbor, name} ->
                on_add_neighbor(rb, name)
            {:remove_neighbor, name} ->
                on_remove_neighbor(rb, name)
            {:link, name} -> send rb, {:link, name}
            {:unlink, name} -> send rb, {:unlink, name}
        end
        listen(upper, rb, seqno, msgbag, next)
    end

    def on_broadcast(rb, bid, seqno, msg) do
        send rb, {:broadcast, bid, {seqno, msg}}
    end

    def on_deliver(upper, msgbag, next, bid, bsrc, msg) do
        {seqno, msg} = msg
        msgbag = MapSet.put(msgbag, {bid, bsrc, seqno, msg})

        if Map.has_key?(next, bsrc) == :false do
            next = Map.put(next, bsrc, 1)
        end

        deliver_internal(upper, msgbag, next, bsrc)
    end

    def deliver_internal(upper, msgbag, next, bsrc) do
        msg = Enum.find(msgbag, fn(m) ->
            {_, m_bsrc, m_seqno, _} = m
            m_bsrc == bsrc and m_seqno == next[bsrc] end)

        if msg != nil do
            {bid, _, seqno, msg} = msg
            send upper, {:deliver, bid, bsrc, seqno, msg}
            msgbag = MapSet.delete(msgbag, msg)
            next = Map.put(next, bsrc, next[bsrc] + 1)
            {msgbag, next} = deliver_internal(upper, msgbag, next, bsrc)
        end

        {msgbag, next}
    end

    def on_add_neighbor(rb, name) do
        send rb, {:add_neighbor, name}
    end

    def on_remove_neighbor(rb, name) do
        send rb, {:remove_neighbor, name}
    end
end
