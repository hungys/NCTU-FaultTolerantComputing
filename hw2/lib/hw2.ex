defmodule Hw2 do
    def init(name) do
        case name do
            "p" ->
                launch("p", "q")
            "q" ->
                launch("q", "p")
            _ ->
                IO.puts("Only p and q are supported!")
        end
    end

    def launch(name, dest) do
        listener = spawn(Hw2, :listen, [dest])
        pl = spawn(PerfectLink, :init, [name, listener])
        sender(pl, dest)
    end

    def listen(dest) do
        receive do
            {:deliver, _, _, msg} -> IO.puts("#{dest}: #{msg}")
        end
        listen(dest)
    end

    def sender(pl, dest) do
        msg = IO.gets("> ")
        msg = String.strip(msg)
        case msg do
            "connect" -> connect(dest)
            "disconnect" -> disconnect(dest)
            _ -> send pl, {:send, dest, UUID.uuid4(), msg}
        end
        sender(pl, dest)
    end

    def connect(dest) do
        case Node.connect(String.to_atom("#{dest}@localhost")) do
            :true -> IO.puts("connected")
            :false -> IO.puts("connect fail")
        end
    end

    def disconnect(dest) do
        case Node.disconnect(String.to_atom("#{dest}@localhost")) do
            :true -> IO.puts("disconnected")
            :false -> IO.puts("disconnect fail")
        end
    end
end
