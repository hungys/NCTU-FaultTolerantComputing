defmodule ReliableBroadcast do
    def init(name, upper) do
        pl = spawn(PerfectLink, :init, [name, self])
        listen(upper, pl, MapSet.new, MapSet.new)
    end

    def listen(upper, pl, neighbors, delivered) do
        receive do
            {:broadcast, bid, msg} ->
                on_broadcast(pl, neighbors, bid, Node.self, msg)
            {:broadcast, bid, bsrc, msg} ->
                on_broadcast(pl, neighbors, bid, bsrc, msg)
            {:deliver, src, mid, msg} ->
                delivered = on_deliver(upper, delivered, src, mid, msg)
            {:add_neighbor, name} ->
                neighbors = on_add_neighbor(neighbors, name)
            {:remove_neighbor, name} ->
                neighbors = on_remove_neighbor(neighbors, name)
        end
        listen(upper, pl, neighbors, delivered)
    end

    def on_broadcast(pl, neighbors, bid, bsrc, msg) do
        Enum.each(neighbors, fn(dest) ->
            send pl, {:send, dest, UUID.uuid4(), {bid, bsrc, msg}} end)
    end

    def on_deliver(upper, delivered, src, mid, msg) do
        {bid, bsrc, msg} = msg
        if MapSet.member?(delivered, bid) == :false do
            delivered = MapSet.put(delivered, bid)
            if bsrc != Node.self do
                send self, {:broadcast, bid, bsrc, msg}
            end
            send upper, {:deliver, bid, bsrc, msg}
        end
        delivered
    end

    def on_add_neighbor(neighbors, name) do
        MapSet.put(neighbors, name)
    end

    def on_remove_neighbor(neighbors, name) do
        MapSet.delete(neighbors, name)
    end
end
