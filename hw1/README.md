HW1: Ping-Pong
==============

# Design

## `PingPong` module

To reuse most of the code for four environments, we encapsulate the client and server routine in `PingPong` module.

For the server function `pong()`, it will execute a loop to receive message from other processes (i.e. client). When receiving *ping* message, it will first sleep for 500ms to simulate transmission delay, then send a *pong* message back. Once a *finished* message received, the loop will break and the server routine is terminated.

```elixir
def pong() do
    receive do
        :finished -> IO.puts("server: finished")
        {:ping, cnt, client_pid} ->
            IO.puts("server: ping ##{cnt} received")
            :timer.sleep(500)
            send client_pid, :pong
            IO.puts("server: pong ##{cnt} sent")
            pong()
    end
end
```

For the client function `ping(n, cnt, server_pid)`, a number `n` is passed in as a counter, the function call will match `ping(0, cnt, server_pid)` when `n` equals to 0. The client simply send a *ping* message to server process, and is blocked immediately to receive a *pong* response. The recursive calls will be terminated when `n` equals to 0.

```elixir
def ping(n, cnt \\ 1, server_pid)   # function header
def ping(0, cnt, server_pid) do
    IO.puts("client: finished")
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
```

## `Hw1.Common` module

The code used for client to connect to server process is encapsulated in `Hw1.Common` module.

The `connect_server_node(host \\ "localhost")` function will try to connect to specific node. The `connect_server_process()` will try to find the PID of server with `:global.whereis_name`.

Noted that we implement `connect_server_process()` as a recursion because we found that we always get `:undefined` from `:global.whereis_name` at the time `connect_server_node()` just finished. This may be due to `Node.connect` is a non-blocking operation, or due to the design of Erlang VM.

```elixir
def connect_server_node(host \\ "localhost") do
    case Node.connect(String.to_atom("server@#{host}")) do
        :true ->
            :timer.sleep(500)   # workaroud: delay for :global.whereis_name
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
```

## `Hw1.Env[1~4]` module

The four environment in spec is implemented in four `Hw1.Env[1~4]` modules separately. These modules use `Hw1.Common` to connect client to server, and execute the client or server routine in `Hw1.PingPong` module. We won't show the detailed implementation in report, they can be found in `lib/hw1.ex`.

# Scenario

## Env1: Single Node

First, start an *iex* shell,

```bash
$ iex -S mix
```

Then, start both client and server in one command,

```elixir
iex(1)> Hw1.Env1.start()   # or Hw1.Env1.start(<NUMBER OF PING>)
```

The output should be similar to the following example,

```
client: ping #1 sent
server: ping #1 received
#PID<0.117.0>
server: pong #1 sent
client: pong #1 received
client: ping #2 sent
server: ping #2 received
server: pong #2 sent
client: pong #2 received
......
client: ping #10 sent
server: ping #10 received
server: pong #10 sent
client: pong #10 received
client: finished
server: finished
```

## Env2: Separate nodes on a single host

To connect two Elixir nodes, we need to specify a name for each node when starting *iex* shell.

First, start an *iex* shell for server,

```elixir
$ iex --sname server@localhost -S mix
......
iex(1)> Hw1.Env2.server()
```

Second, start another *iex* shell for client,

```elixir
$ iex --sname client@localhost -S mix
......
iex(1)> Hw1.Env2.client()   # or Hw1.Env2.client(<NUMBER OF PING>)
```

Then you will see the similar output as Env1, but separated in two terminals.

For the `client` function (also applied for Env3~4), you can always pass an optional argument to specify the number of ping message to send.

## Env3: Separate hosts on the same LAN

To simulate Env3, we prepare two Ubuntu VMs. We can get their IP with `ifconfig` command. Noticed that in this configuration, we need to specify a common **cookie** when starting *iex* shell, otherwise the connection will be refused.

First, start an *iex* shell in VM #1 for server,

```elixir
$ iex --name server@<IP OF VM1> --cookie nctu_ftc_hw1 -S mix
......
iex(1)> Hw1.Env3.server()
```

Second, start an *iex* shell in VM #2 for server,

```elixir
$ iex --name client@<IP OF VM2> --cookie nctu_ftc_hw1 -S mix
......
iex(1)> Hw1.Env3.client("<IP OF VM1>")
```

Then you will see the same result as Env2 even if two nodes are located on different hosts.

## Env4: Separate hosts on different LANs

For this configuration, we need to setup a VPN to let two hosts on different LANs act as they are in the same virtual network.

We have an Ubuntu VM in Lab network (under `192.168.1.0/24` subnet) and also a OS X laptop in Home network (under `192.168.0.0/24` subnet).

First, on OS X laptop, we set up a VPN connection to Lab's AP, and we get a new IP address under `192.168.1.0/24` subnet. Now two computer can inteact with each other just like they are in the same LAN (Lab network).

Now, just repeat the same steps as in Env3, because we can regard them as in the same LAN.

On Home's computer, start the server,

```elixir
$ iex --name server@<IP OF SERVER> --cookie nctu_ftc_hw1 -S mix
......
iex(1)> Hw1.Env4.server()
```

On Lab's computer, start the client,

```elixir
$ iex --name client@<IP OF CLIENT> --cookie nctu_ftc_hw1 -S mix
......
iex(1)> Hw1.Env4.client("<IP OF SERVER>")
```
