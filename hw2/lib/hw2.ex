defmodule Hw2 do
    def init(name, link \\ "perfect") do
        case name do
            "p" ->
                launch("p", "q", link)
            "q" ->
                launch("q", "p", link)
            _ ->
                IO.puts("Only p and q are supported!")
        end
    end

    def launch(name, dest, link) do
        listener = spawn(Hw2, :listen, [dest])
        case link do
            "perfect" ->
                pl = spawn(PerfectLink, :init, [name, listener])
                sender(pl, dest)
            "stubborn" ->
                sl = spawn(StubbornLink, :init, [name, listener])
                sender(sl, dest)
            "fairloss" ->
                fl = spawn(FairlossLink, :init, [name, listener])
                sender(fl, dest)
            _ -> IO.puts("Unsupported link type: #{link}")
        end
    end

    def listen(dest) do
        receive do
            {:deliver, _, _, msg} -> IO.puts("#{dest}: #{msg}")
        end
        listen(dest)
    end

    def sender(link, dest) do
        msg = IO.gets("> ")
        msg = String.strip(msg)
        case msg do
            "connect" -> connect(dest)
            "disconnect" -> disconnect(dest)
            _ -> send link, {:send, dest, UUID.uuid4(), msg}
        end
        sender(link, dest)
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
