defmodule FairlossLink do
    @lossrate 0.00005

    def init(name, upper) do
        :global.register_name(name, self)
        listen(name, upper, MapSet.new([name]))
    end

    def listen(name, upper, links) do
        receive do
            {:send, dest, mid, :ack} -> on_send(name, dest, mid, :ack, links)
            {:send, dest, mid, msg} -> on_send(name, dest, mid, msg, links)
            {:deliver, src, mid, msg} -> on_deliver(upper, src, mid, msg)
            {:ack, src, mid} -> on_ack(upper, src, mid)
            {:link, name} -> links = MapSet.put(links, name)
            {:unlink, name} -> links = MapSet.delete(links, name)
        end
        listen(name, upper, links)
    end

    def on_send(name, dest, mid, :ack, links) do
        pid = :global.whereis_name(dest)
        if MapSet.member?(links, dest) and pid != :undefined and is_packet_loss?(:ack) == :false do
            send pid, {:ack, name, mid}
        end
    end

    def on_send(name, dest, mid, msg, links) do
        pid = :global.whereis_name(dest)
        if MapSet.member?(links, dest) and pid != :undefined and is_packet_loss?(msg) == :false do
            send pid, {:deliver, name, mid, msg}
        end
    end

    def on_deliver(upper, src, mid, msg) do
        send upper, {:deliver, src, mid, msg}
    end

    def on_ack(upper, src, mid) do
        send upper, {:ack, src, mid}
    end

    def is_packet_loss?(msg) do
        cond do
            msg == :start_exp or msg == :end_exp -> :false
            :random.uniform() < @lossrate ->
                # IO.puts("packet loss")
                :true
            :true -> :false
        end
    end
end
