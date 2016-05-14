defmodule Hw3 do
    def init(type \\ :fifo) do
        listener = spawn(Hw3, :listen, [])
        bcast = nil

        case type do
            :fifo ->
                bcast = spawn(FIFOBroadcast, :init, [Node.self, listener])
            :reliable ->
                bcast = spawn(ReliableBroadcast, :init, [Node.self, listener])
            _ -> IO.puts("Unsupported broadcast type: #{type}")
        end

        if bcast != nil do
            send bcast, {:add_neighbor, Node.self}
            node_loop(bcast)
        end
    end

    def node_loop(bcast) do
        msg = IO.gets("(#{Node.self})> ")
        msg = String.strip(msg)
        tokens = String.split(msg, " ")
        case Enum.at(tokens, 0) do
            "neighbor" -> neighbor(bcast, Enum.at(tokens, 1))
            "connect" -> connect(Enum.at(tokens, 1))
            "disconnect" -> disconnect(Enum.at(tokens, 1))
            _ -> broadcast(bcast, msg)
        end
        node_loop(bcast)
    end

    def listen() do
        receive do
            {:deliver, bid, bsrc, msg} ->
                IO.puts(msg)
            {:deliver, bid, bsrc, seqno, msg} ->
                IO.puts(msg)
        end
        listen
    end

    def neighbor(bcast, name) do
        connect(name)
        send bcast, {:add_neighbor, String.to_atom("#{name}@localhost")}
    end

    def connect(name) do
        Node.connect(String.to_atom("#{name}@localhost"))
    end

    def disconnect(name) do
        Node.disconnect(String.to_atom("#{name}@localhost"))
    end

    def broadcast(bcast, msg) do
        send bcast, {:broadcast, UUID.uuid4(), msg}
    end
end
