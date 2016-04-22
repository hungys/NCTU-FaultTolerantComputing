defmodule Hw2 do
    @msgsize 4096
    @msgcount 256000

    def init(link \\ :perfect, mode \\ :normal) do
        case Node.self do
            :p@localhost ->
                launch(:p@localhost, :q@localhost, link, mode)
            :q@localhost ->
                launch(:q@localhost, :p@localhost, link, mode)
            _ ->
                IO.puts("Only p and q are supported!")
        end
    end

    def launch(name, dest, link, mode) do
        listener = spawn(Hw2, :listen, [dest, link, mode, 0])
        case link do
            :perfect ->
                pl = spawn(PerfectLink, :init, [name, listener])
                sender(pl, dest)
            :stubborn ->
                sl = spawn(StubbornLink, :init, [name, listener])
                sender(sl, dest)
            :fairloss ->
                fl = spawn(FairlossLink, :init, [name, listener])
                sender(fl, dest)
            _ -> IO.puts("Unsupported link type: #{link}")
        end
    end

    def listen(dest, link, :normal, cnt) do
        receive do
            {:deliver, _, _, msg} -> IO.puts("#{dest}: #{msg}")
        end
        listen(dest, link, :normal, cnt)
    end

    def listen(dest, link, :exp, cnt) do
        receive do
            {:deliver, _, _, :start_exp} ->
                ts = :os.system_time(:milli_seconds)
                IO.puts("Experiment starts at #{ts}")
            {:deliver, _, _, :end_exp} ->
                if link == :fairloss do
                    ts = :os.system_time(:milli_seconds)
                    IO.puts("Experiment ends at #{ts}")
                end
            _ -> :true
        end

        cnt = cnt + 1
        if link == :perfect do
            if cnt == @msgcount + 2 do
                ts = :os.system_time(:milli_seconds)
                IO.puts("Experiment ends at #{ts}")
            end
        end

        cond do
            cnt > (@msgcount - 1000) -> IO.puts(cnt)
            rem(cnt, 1000) == 0 -> IO.write(".")
            true -> :true
        end

        listen(dest, link, :exp, cnt)
    end

    def sender(link, dest) do
        msg = IO.gets("> ")
        msg = String.strip(msg)
        case msg do
            "connect" -> connect(dest)
            "disconnect" -> disconnect(dest)
            "exp" ->
                send link, {:send, dest, UUID.uuid4(), :start_exp}
                exp(link, dest, generate_random_string(@msgsize), @msgcount)
            _ -> send link, {:send, dest, UUID.uuid4(), msg}
        end
        sender(link, dest)
    end

    def connect(dest) do
        case Node.connect(dest) do
            :true -> IO.puts("connected")
            :false -> IO.puts("connect fail")
        end
    end

    def disconnect(dest) do
        case Node.disconnect(dest) do
            :true -> IO.puts("disconnected")
            :false -> IO.puts("disconnect fail")
        end
    end

    def exp(link, dest, msg, 0) do
        send link, {:send, dest, UUID.uuid4(), :end_exp}
    end

    def exp(link, dest, msg, cnt) do
        send link, {:send, dest, UUID.uuid4(), msg}
        exp(link, dest, msg, cnt - 1)
    end

    def generate_random_string(length) do
        :crypto.strong_rand_bytes(length) |> Base.url_encode64 |> binary_part(0, length)
    end
end
