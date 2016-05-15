HW3: FIFO Broadcast
===================

# Design

In this homework, we implement two kinds of broadcast protocol, which are *reliable broadcast* and *FIFO broadcast*. We leverage *perfect link* that we implemented in HW2 as the underlying communication link.

Since FIFO broadcast is based on reliable broadcast, we adopt the similar design concept as HW2 to implement each broadcast protocol as an actor. In this way, if an application want to use FIFO broadcast protocol, it will first spawn a `FIFOBroadcast` actor, and behind the scene, a `ReliableBroadcast` actor is also created to serve as the underlying layer.

## Modifications to `FairlossLink` module

In Elixir, once the node is connected to another node with `Node.connect` API, `Node.list` will return not only the neighbor nodes, but also all the **reachable** nodes in the network. To simulate the link outage between nodes, we maintain an additional set which stores the link status to neighbors for each node's communication link. (See `links` set in `fairloss_link.ex`)

## `ReliableBroadcast` module

The `ReliableBroadcast` module is the most fundamental protocol for broadcasting messages. It will distribute the message through the `send` interface of `PerfectLink` to all the neighbors. In the meantime, it processes the messages that were delivered by bottom layer.

![ReliableBroadcast](http://i.imgur.com/qhFDiGn.png)

As shown in the pseudo code, the same messages will only be delivered one time. Furthermore, the receiver node will broadcast the message again to the neighbors to make all the reachable nodes in the network be able to receive the message.

## `FIFOBroadcast` module

![FIFOBroadcast](http://i.imgur.com/abJFse4.png)

The `FIFOBroadcast` module is built on top of `ReliableBroadcast` module. To broadcast a message, the message is first attached with a increasing **sequence number** and then proxied to the underlying layer. As for message delivery, a set of `next` values are used to ensure the FIFO-ordering for each source respectively.

# Usage

Since the program has a dependency to a third-party package for generating the UUIDs, you should fetch the dependecies first.

```bash
$ mix deps.get
```

Then, you should use `mix` to compile the project,

```bash
$ mix compile
```

Now you can use `iex` to launch an interactive shell,

```bash
$ iex --sname a@localhost -S mix
```

In iex shell, you can start a node by,

```elixir
iex(a@localhost)1> Hw3.init()
(a@localhost)>
```

Under hw3 CLI, you are able to type and broadcast messages to all the reachable nodes in the network. Before that, you need to configure the neighbor nodes by using `neighbor` command,

```elixir
(a@localhost)> neighbor b
Connected to b.
(a@localhost)> neighbor c
Connected to c.
```

For the convenience, we also provide some pre-configured topologies,

```elixir
(a@localhost)> topo ring4
Connected to b.
Connected to c.
```

The `topo` command will call `neighbor` for you correspondingly to form a topology. The fully supported options are listed below,

- `full3`: a~c, all pairs are connected.
- `full4`: a~d, all pairs are connected.
- `full5`: a~e, all pairs are connected.
- `ring3`: a~c form a ring topology clockwisely.
- `ring4`: a~d form a ring topology clockwisely.
- `ring5`: a~e form a ring topology clockwisely.
- `star4`: a as central node, and node b~d are connected to a.

To simulate link outage, `disconnect <node>` and `connect <node>` command can be used,

```elixir
(a@localhost)> disconnect b   # Must be a neighbor
Disconnected from b.
(a@localhost)> connect b
Connected to b.
```

# Experiments

## Correctness

### `ReliableBroadcast` module

To verify the correctness of `ReliableBroadcast`, we implement a validation method that can be called each time when the message is delivered,

```elixir
def validate_reliable(delivered, bsrc, msg) do
    if Map.has_key?(delivered, bsrc) == :false do
        delivered = Map.put(delivered, bsrc, [])
    end

    delivered = Map.put(delivered, bsrc, delivered[bsrc] ++ [msg])
    IO.puts("----- hash(#{bsrc}) = #{md5(Enum.sort(delivered[bsrc]))}")

    delivered
end
```

The message broadcasted by `bsrc` is inserted to an exclusive list `delivered[bsrc]`. The **sorted** list (i.e. `Enum.sort(delivered[bsrc])`) is passed into `md5` function to calculate a hash. Although `ReliableBroadcast` does not guarantee the FIFO-ordering of messages, the hash value calculated in this way must be identical across all the nodes.

For example, in a `ring3` network, we broadcast three messages in a row, and then check if all final hash values are identical.

```elixir
iex(a@localhost)1> Hw3.init(:reliable)
(a@localhost)> topo ring3
Connected to b.
Connected to c.
(a@localhost)> disconnect b
Disconnectted from b.
(a@localhost)> disconnect c
Disconnectted from c.
(a@localhost)> Hello 1
a@localhost: Hello 1
----- hash(a@localhost) = 9cdbde8e26efc28156e810237b67b98c
(a@localhost)> Hello 2
a@localhost: Hello 2
----- hash(a@localhost) = 63db35576b0c3dba367fd2444cb428aa
(a@localhost)> Hello 3
a@localhost: Hello 3
----- hash(a@localhost) = 005c1f463a1c114edabe1d4dfd7dd789
(a@localhost)> connect b
Connected to b.
(a@localhost)> connect c
Connected to c.
```

```elixir
iex(b@localhost)1> Hw3.init(:reliable)
(b@localhost)> topo ring3
Connected to a.
Connected to c.
a@localhost: Hello 1
----- hash(a@localhost) = 9cdbde8e26efc28156e810237b67b98c
a@localhost: Hello 3
----- hash(a@localhost) = f9c60a27cfdb7c372518a2735fbbeae7
a@localhost: Hello 2
----- hash(a@localhost) = 005c1f463a1c114edabe1d4dfd7dd789
```

```elixir
iex(c@localhost)1> Hw3.init(:reliable)
(c@localhost)> topo ring3
Connected to a.
Connected to b.
a@localhost: Hello 2
----- hash(a@localhost) = f15d33a1a1c5dc564c0c16959a296c00
a@localhost: Hello 1
----- hash(a@localhost) = 63db35576b0c3dba367fd2444cb428aa
a@localhost: Hello 3
----- hash(a@localhost) = 005c1f463a1c114edabe1d4dfd7dd789
```

In the above example, we can see that no matter the messages are delivered in which order, the final md5 hash of the **sorted delivered list** are identical on all nodes (i.e. `005c1f463a1c114edabe1d4dfd7dd789` in this example). Hence, we have proved **Validity**, **Agreement**, and **Integrity** properties for reliable broadcast.

### `FIFOBroadcast` module

To verify the correctness of `ReliableBroadcast`, we implement another validation method that can be called each time when the message is delivered,

```elixir
def validate_fifo(delivered, bsrc, msg) do
    if Map.has_key?(delivered, bsrc) == :false do
        delivered = Map.put(delivered, bsrc, "")
    end

    delivered = Map.put(delivered, bsrc, delivered[bsrc] <> msg)
    IO.puts("----- hash(#{bsrc}) = #{md5(delivered[bsrc])}")

    delivered
end
```

The message broadcasted by `bsrc` is **concatenated** to a exclusive string `delivered[bsrc]`. Since `FIFOBroadcast` guarantees the FIFO-ordering of messages, the hash value of the string must be identical across all the nodes.

For example, in a `ring3` network, we broadcast three messages in a row, and then check if all final hash values are identical.

```elixir
iex(a@localhost)1> Hw3.init(:fifo)
(a@localhost)> topo ring3
Connected to b.
Connected to c.
(a@localhost)> Hello 1
a@localhost: (seqno=1) Hello 1
----- hash(a@localhost) = 9cdbde8e26efc28156e810237b67b98c
(a@localhost)> Hello 2
a@localhost: (seqno=2) Hello 2
----- hash(a@localhost) = 63db35576b0c3dba367fd2444cb428aa
(a@localhost)> Hello 3
a@localhost: (seqno=3) Hello 3
----- hash(a@localhost) = 005c1f463a1c114edabe1d4dfd7dd789
```

```elixir
iex(b@localhost)1> Hw3.init(:fifo)
(b@localhost)> topo ring3
Connected to a.
Connected to c.
a@localhost: (seqno=1) Hello 1
----- hash(a@localhost) = 9cdbde8e26efc28156e810237b67b98c
a@localhost: (seqno=2) Hello 2
----- hash(a@localhost) = 63db35576b0c3dba367fd2444cb428aa
a@localhost: (seqno=3) Hello 3
----- hash(a@localhost) = 005c1f463a1c114edabe1d4dfd7dd789
```

```elixir
iex(c@localhost)1> Hw3.init(:fifo)
(c@localhost)> topo ring3
Connected to a.
Connected to b.
a@localhost: (seqno=1) Hello 1
----- hash(a@localhost) = 9cdbde8e26efc28156e810237b67b98c
a@localhost: (seqno=2) Hello 2
----- hash(a@localhost) = 63db35576b0c3dba367fd2444cb428aa
a@localhost: (seqno=3) Hello 3
----- hash(a@localhost) = 005c1f463a1c114edabe1d4dfd7dd789
```

In the above example, we can see that the md5 hash of **concatenated messages** are identical on all nodes (i.e. `005c1f463a1c114edabe1d4dfd7dd789` in this example). With this fact, we have proved **FIFO order** property for FIFO broadcast.

## Performance

To run the performance test, you should initialize the node with special options. For exmaple, in command `Hw3.init(:fifo, :exp, :false)`, the second parameter `:exp` indicates that the node will run in experiment mode, and the messages will not print to the console to reduce the I/O overhead; the third parameter `:false` indicates that the md5 validation will not be executed.

We also provide an useful command `perf <number>` to broadcast batch messages. For example, to broadcast 1000 messages in a row (`Hello World` by default),

```elixir
(a@localhost)> perf 1000
Experiment starts at 1463245992040
.........................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................
Experiment ends at 1463245992571
(a@localhost)>
```

The **throughput (message per second)** can be calculated by `number of messages / (ends_time - start_time)`.

We measure the performance under the following configurations,

- message output (standard I/O): **OFF** (only print dot `.`)
- md5 validation: **OFF**
- packet loss rate of `FairlossLink`: **0.05%**
- timeout of `StubbornLink`: **10 sec**

![performance comparison](http://i.imgur.com/Bx2StRb.png)

The throughput of reliable broadcast protocol is stable across all the tests. However, for the FIFO broadcast protocol, the more batch messages sent, the higher slow down gained. The main reason of the slow down is that the FIFO broadcast protocol need to ensure the FIFO-ordering, and this may delay the process of message delivery, especially when packet loss occurs.
