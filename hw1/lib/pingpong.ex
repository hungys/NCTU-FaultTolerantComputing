defmodule PingPong do
    def ping(n, cnt \\ 1, server_pid)
    def ping(0, cnt, server_pid) do
        send server_pid, :finished
    end

    def ping(n, cnt, server_pid) do
        send server_pid, {:ping, cnt, self}
        IO.puts("client: ping ##{cnt} sent")
        receive do
            :pong -> IO.puts("client: pong ##{cnt} received")
        end
        :timer.sleep(500)
        ping(n - 1, cnt + 1, server_pid)
    end

    def pong() do
        receive do
            :finished -> IO.puts("server: finished")
            {:ping, cnt, client_pid} ->
                IO.puts("server: ping ##{cnt} received")
                :timer.sleep(500)
                send client_pid, :pong
                IO.puts("server: pong ##{cnt} sent")
        end
        pong()
    end
end
