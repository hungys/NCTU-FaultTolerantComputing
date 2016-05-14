defmodule Hw3 do
    def init(type \\ :fifo, validation \\ :true) do
        listener = spawn(Hw3, :listen, [Map.new, validation])
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
            "connect" -> connect(bcast, Enum.at(tokens, 1))
            "disconnect" -> disconnect(bcast, Enum.at(tokens, 1))
            "topo" -> topo(bcast, Enum.at(tokens, 1))
            _ -> broadcast(bcast, msg)
        end
        node_loop(bcast)
    end

    def listen(delivered, validation \\ :false) do
        receive do
            {:deliver, _, bsrc, msg} ->
                IO.puts("#{bsrc}: #{msg}")
                if validation == :true do
                    delivered = validate_reliable(delivered, bsrc, msg)
                end
            {:deliver, _, bsrc, seqno, msg} ->
                IO.puts("#{bsrc}: (seqno=#{seqno}) #{msg}")
                if validation == :true do
                    delivered = validate_fifo(delivered, bsrc, msg)
                end
        end
        listen(delivered, validation)
    end

    def neighbor(bcast, name) do
        connect(bcast, name)
        send bcast, {:add_neighbor, String.to_atom("#{name}@localhost")}
    end

    def connect(bcast, name) do
        node = String.to_atom("#{name}@localhost")
        send bcast, {:link, node}
        if Node.connect(node) do
            IO.puts("Connected to #{name}.")
        end
    end

    def disconnect(bcast, name) do
        node = String.to_atom("#{name}@localhost")
        send bcast, {:unlink, node}
        if Node.disconnect(node) do
            IO.puts("Disconnectted from #{name}.")
        end
    end

    def broadcast(bcast, msg) do
        send bcast, {:broadcast, UUID.uuid4(), msg}
    end

    def validate_reliable(delivered, bsrc, msg) do
        if Map.has_key?(delivered, bsrc) == :false do
            delivered = Map.put(delivered, bsrc, [])
        end

        delivered = Map.put(delivered, bsrc, delivered[bsrc] ++ [msg])
        IO.puts("----- hash(#{bsrc}) = #{md5(Enum.sort(delivered[bsrc]))}")

        delivered
    end

    def validate_fifo(delivered, bsrc, msg) do
        if Map.has_key?(delivered, bsrc) == :false do
            delivered = Map.put(delivered, bsrc, "")
        end

        delivered = Map.put(delivered, bsrc, delivered[bsrc] <> msg)
        IO.puts("----- hash(#{bsrc}) = #{md5(delivered[bsrc])}")

        delivered
    end

    def md5(data) do
        Base.encode16(:erlang.md5(data), case: :lower)
    end

    def topo(bcast, id) do
        name = Atom.to_string(Node.self)
        name = Enum.at(String.split(name, "@"), 0)

        case id do
            "full3" ->
                nodes = ["a", "b", "c"]
                Enum.each(nodes, fn(n) ->
                    if n != name do
                        neighbor(bcast, n)
                    end
                end)
            "full4" ->
                nodes = ["a", "b", "c", "d"]
                Enum.each(nodes, fn(n) ->
                    if n != name do
                        neighbor(bcast, n)
                    end
                end)
            "full5" ->
                nodes = ["a", "b", "c", "d", "e"]
                Enum.each(nodes, fn(n) ->
                    if n != name do
                        neighbor(bcast, n)
                    end
                end)
            "ring3" ->
                case name do
                    "a" ->
                        neighbor(bcast, "b")
                        neighbor(bcast, "c")
                    "b" ->
                        neighbor(bcast, "a")
                        neighbor(bcast, "c")
                    "c" ->
                        neighbor(bcast, "a")
                        neighbor(bcast, "b")
                end
            "ring4" ->
                case name do
                    "a" ->
                        neighbor(bcast, "b")
                        neighbor(bcast, "c")
                    "b" ->
                        neighbor(bcast, "a")
                        neighbor(bcast, "d")
                    "c" ->
                        neighbor(bcast, "a")
                        neighbor(bcast, "d")
                    "d" ->
                        neighbor(bcast, "b")
                        neighbor(bcast, "c")
                end
            "ring5" ->
                case name do
                    "a" ->
                        neighbor(bcast, "b")
                        neighbor(bcast, "e")
                    "b" ->
                        neighbor(bcast, "a")
                        neighbor(bcast, "c")
                    "c" ->
                        neighbor(bcast, "b")
                        neighbor(bcast, "d")
                    "d" ->
                        neighbor(bcast, "c")
                        neighbor(bcast, "e")
                    "e" ->
                        neighbor(bcast, "a")
                        neighbor(bcast, "d")
                end
            "star4" ->
                case name do
                    "a" ->
                        neighbor(bcast, "b")
                        neighbor(bcast, "c")
                        neighbor(bcast, "d")
                    "b" ->
                        neighbor(bcast, "a")
                    "c" ->
                        neighbor(bcast, "a")
                    "d" ->
                        neighbor(bcast, "a")
                end
        end
    end
end
