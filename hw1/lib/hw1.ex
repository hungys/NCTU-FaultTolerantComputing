defmodule Hw1.Common do
    def connect_server_node(host \\ "localhost") do
        case Node.connect(String.to_atom("server@#{host}")) do
            :true ->
                :timer.sleep(500)
                :true
            :false ->
                IO.puts("client: cannot connect to server node, retry again...")
                :timer.sleep(3000)
                connect_server_node()
        end
    end

    def connect_server_process() do
        case :global.whereis_name(:server) do
            :undefined ->
                IO.puts("client: cannot find server process, retry again...")
                :timer.sleep(3000)
                connect_server_process()
            pid -> pid
        end
    end
end

defmodule Hw1.Env1 do
    def start(n \\ 10) do
        server = spawn(PingPong, :pong, [])
        spawn(PingPong, :ping, [n, server])
    end
end

defmodule Hw1.Env2 do
    alias Hw1.Common

    def client(n \\ 10) do
        Common.connect_server_node()
        server = Common.connect_server_process()
        spawn(PingPong, :ping, [n, server])
    end

    def server() do
        server = spawn(PingPong, :pong, [])
        :global.register_name(:server, server)
    end
end

defmodule Hw1.Env3 do
    alias Hw1.Common

    def client(server_host, n \\ 10) do
        Node.set_cookie(:nctu_ftc_hw1)
        Common.connect_server_node(server_host)
        server = Common.connect_server_process()
        spawn(PingPong, :ping, [n, server])
    end

    def server() do
        Node.set_cookie(:nctu_ftc_hw1)
        server = spawn(PingPong, :pong, [])
        :global.register_name(:server, server)
    end
end

defmodule Hw1.Env4 do
    alias Hw1.Env3

    def client(server_host, n \\ 10) do
        Env3.client(server_host, n)
    end

    def server() do
        Env3.server()
    end
end
