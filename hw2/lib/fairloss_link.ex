defmodule FairlossLink do
    @lossrate 0.00002

    def init(name, upper) do
        :global.register_name(name, self)
        listen(upper)
    end

    def listen(upper) do
        receive do
            {:send, dest, mid, :ack} -> on_send(dest, mid, :ack)
            {:send, dest, mid, msg} -> on_send(dest, mid, msg)
            {:deliver, src, mid, msg} -> on_deliver(upper, src, mid, msg)
            {:ack, src, mid} -> on_ack(upper, src, mid)
        end
        listen(upper)
    end

    def on_send(pid, mid, :ack) do
        if pid != :undefined and is_packet_loss?(:ack) == :false do
            send pid, {:ack, self, mid}
        end
    end

    def on_send(dest, mid, msg) do
        pid = :global.whereis_name(dest)
        if pid != :undefined and is_packet_loss?(msg) == :false do
            send pid, {:deliver, self, mid, msg}
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
