HW2: Perfect Link
=================

# Design

In this homework, we implement three modules to support various communication links, including *Perfect Link*, *Stubborn Link*, and *Fair-loss Link*. The design concept is to implement each link type as an actor, the actor exposes the interface to upper layer (either a link layer or a application program), and spawn another actors for underlying communication link.

![Architecture](http://i.imgur.com/0hDH2zy.png)

For example, if a program in application layer want to transfer data via a perfect link, it will first spawn a `PerfectLink` actor and manipulate with it directly. Behind the scene, since `PerfectLink` leverages `StubbornLink`, it will spawn a `StubbornLink` actor silently. In similar way, the `StubbornLink` will spawn a `FairlossLink` actor as the underlying communication link.

## `FairlossLink` module

The `FairlossLink` module is the most bottom layer in our program, and it will use Elixir APIs, including `send` and `receive`, to perform the actual data exchange between Erlang VM nodes.

To simulate the packet loss, we use random technique to establish a simple probability model, to implement a nearly **fair** loss link. The value of packet loss rate is hard coded as a constant, `@lossrate`, in `fairloss_link.ex`.

## `StubbornLink` module

![Retransmit Forever](http://i.imgur.com/nOdjCDi.png)

The `StubbornLink` module leverages `FairlossLink` as the underlying communication link. For performance optimization, we introduce **ACK** mechanism in this layer to prevent the link keeps retransmitting the messages which have been delivered by destination node.

Notice that we don't guarantee the FIFO ordering for message retransmission, but only guarantee **Reliable delivery** property.

## `PerfectLink` module

![Eliminate Duplicates](http://i.imgur.com/cuKEKp3.png)

The `PerfectLink` module leverages `StubbornLink` as the underlying communication link. Our implementation is the same as the pseudo code from textbook, without introducing **ACK for ACK** mechanism and timestamp comparison to limit the growth of `delivered` set.

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
$ iex --sname p@localhost -S mix
```

In iex shell, you can start a process by,

```elixir
iex(q@localhost)1> Hw2.init()
(hw2)>
```

Under hw2 CLI, you are able to type and send messages to each other (i.e. from p->q or q->p), but you need to first connect from node *p* to node *q* using the helper command,

```elixir
(hw2)> connect
connected
```

In addition, a helper command `disconnect` is also supported for simulating the link outage.

# Experiments

## Correctness

To prove the correctness of our implementation, we launch two nodes and send messages to each other, and check if the **No duplication** and **No creation** properties hold.

For the **Reliable delivery** property, we can use `disconnect` and `connect` helper command to simulate the link outage. Even if the underlying link is disconnected, the data will be eventually transmitted to destination and delivered by the node after the link is reconnected by `connect` command.

![Correctness](http://i.imgur.com/syZJmUi.png)

## Data Rate

In experiments of data rate, we launch two nodes (i.e. *p* and *q*) and sent 512000 4KB messages, which are equivalent to 2GB in total, from *p* to *q* with different packet loss rate respectively.

### Perfect Link

To run this experiment, we first launch a node *q* as a receiver:

```elixir
$ iex --sname q@localhost -S mix
iex(q@localhost)1> Hw2.init(:perfect, :exp)
(hw2)>
```

Then we launch another node *p* as a sender, connect it to node *q*, and start the experiment:

```elixir
$ iex --sname p@localhost -S mix
iex(p@localhost)1> Hw2.init(:perfect, :exp)
(hw2)> connect
connected
(hw2)> exp
```

On termial of node *q*, we can check the progress of data transmission and the final statistics including actual packet loss rate and the time of start and end. The following figures show the result of this experiment.

![Perfect Link result](http://i.imgur.com/CLnlW2J.png)

![Perfect Link chart](http://i.imgur.com/VMj0Rlo.png)

The results match our expectations that the lower packet loss rate gains higher average data rate, because higher packet loss rate needs more data retransmissions involving in underlying communication link.

### Non-perfect Link

The way to launch the experiment is very similar to the previous one, except that we replace the link option `:perfect` with `:fairloss`, which means to transfer data with a non-perfect link.

![Non-perfect Link result](http://i.imgur.com/Swt1oCo.png)

![Non-perfect Link chart](http://i.imgur.com/J05vE9E.png)

The results also match our expectations that the difference of data rate between each packet loss rate is within a small range, because the higher packet loss rate means the less data exchanged involved and less time consumed.
