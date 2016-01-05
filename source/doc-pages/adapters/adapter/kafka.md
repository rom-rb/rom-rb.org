# Kafka Adapter

ROM supports [Apache Kafka][kafka] via [rom-kafka][rom-kafka] adapter, that is built on top of the [poseidon][poseidon] ruby driver.

*Before v0.0.1 the adapter is still in alpha/beta. If you find any inconsistency, please feel free to ask your questions at the [ROM chatroom][rom-gitter] and report issues [on github][rom-kafka].*

## Intro

The adapter provides access to Kafka brokers in much the same way as other adapters do for corresponding datastores with some specifics:

- By the very nature of Kafka, it allows only creating (publishing) messages, and reading (consuming) them. No 'update' and 'delete' commands are available.

- Reading messages from Kafka also differs from what you'd expect from a database. Kafka only supports reading a sequence of messages from a *topic*'s *partition*, starting from some *offset* . You can neither reorder messages or filter them in any way. That operations are up to domain application. All you can define is the topic ([relation](#relation)), its [partition](#partition), the initial [offset](#offset), and [limit](#limit) the number of messages to output.

## Setup

Set a Kafka gateway in a [ROM generic way][rom-setup]. When setting a gateway you have to specify the `client_id` and a list of Kafka brokers.
Brokers can be set in the following ways:

```ruby
# by default (connects to host 'localhost', port 9092)
ROM.setup(:kafka, client_id: :admin)

# with inline address (host:port)
ROM.setup(:kafka, 'localhost:9092', client_id: :admin)

# ...or a list of addresses
ROM.setup(:kafka, '127.0.0.1:9092', '127.0.0.2:9092', client_id: :admin)

# with explicit array of `hosts` and `port`
ROM.setup(:kafka, hosts: ['127.0.0.1', '127.0.0.2'], port: 9092, client_id: :admin)

# or their combination (the same as '127.0.0.1:9092', '127.0.0.1:9093')
ROM.setup(:kafka, '127.0.0.1', hosts: ['127.0.0.2:9093'], port: 9092, client_id: :admin)
```

### Additional options

In addition to `brokers` and `client_id` you can use the following options:

| Attribute | Type | Default value | Description |
| --------- | ---- | ------------- | ----------- |
| `:partitioner` | `Proc`, `nil` | `nil` | A proc used to define partition by key. |
| `:compression_codec` | `:gzip`, `:snappy`, `nil` | `nil` | The type of compression to be used. |
| `:metadata_refresh_interval_ms` | `Integer` | `600_000` | How frequently the topic metadata should be updated (in milliseconds). |
| `:max_send_retries` | `Integer` | `3` | The number of times to retry sending of messages to a Kafka leader. |
| `:retry_backoff_ms` | `Integer` | `100` | The amount of time (in milliseconds) to wait before refreshing the metadata after we are unable to send messages. |
| `:required_acks` | `Integer` | `0` | The number of acks required per request. |
| `:ack_timeout_ms` | `Integer` | `1_500` | How long the producer waits for acks. |
| `:socket_timeout_ms` | `Integer` | `10_000` | How long the producer/consumer socket waits for any reply from server. |
| `:min_bytes` | `Integer` | `1` | The smallest amount of data the server should send (By default send data as soon as it is ready). |
| `:max_bytes` | `Integer` | `1_048_576` | The maximum number of bytes to fetch by consumer (1MB by default). |
| `:max_wait_ms` | `Integer` | `100` | How long to block until the server sends data.  This is only enforced if min_bytes is > 0. |

### Partitioner

With the `:partitioner` option you can specify a procedure to define a partition by key. The procedure should take 2 arguments for key and number of partitions, and return the integer value for a partition.

In the following example a message is added to a corresponding partition depending on number of letters in a key:

```ruby
ROM.setup(
  :kafka,
  client_id: :admin,
  partitioner: -> key, number { key.count % number }
)

#...

ROM.finalize
rom = ROM.env
insert = ROM.command(:items).create

# Suppose the topic "items" has 3 partitions (0 and 1).
# Messages "bar" and "baz" will be added to the partition 1 ("foo".count % 2 = 1).
insert.with(key: "foo").call "bar", "baz"
```

### Compression

To use snappy compression, install the [snappy][snappy] gem, or simply add gem 'snappy' to your project's Gemfile.

## Relations

In `ROM::Kafka` the relation describes a topic. You can read messages from a specific partition from a specified offset.
By default both the partition and initial offset are set to 0.

To define a Kafka relation follow [the standard way of defining relations][rom-relations] in ROM.

```ruby
class Greetings < ROM::Relation[:kafka]
  topic :greetings # kafka-specific alias for `relation :greetings`
end
```

To define relations that are exposed to you application you can define your own methods using dataset modifiers:

- `#from` to define a partition to read data from (0 by default).
- `#offset` to define a *starting* offset to start reading from (0 by default).
- `#limit` to define a number of messages to be fetched.
- `#using` to modify any option of the setup.

The relation `call` method returns an array of tuples with 4 keys:

- `value` for the message.
- `topic` for the current topic.
- `key` for the current key.
- `offset` for the offset of the current message.

```ruby
# After the setup
rom = ROM.finalize.env
greetings = rom.relation(:greetings)

# Selects all messages from the (default) partition 0
greetings.call.to_a
# => [
#      { value: "Hi!", topic: "greetings", key: nil, offset: 0 },
#      { value: "Hello!", topic: "greetings", key: nil, offset: 1 }
#    ]
```

### Partition

By default messages are read from 0 partition. You can explicitly select the partition to read from:

```ruby
# Will read all messages from the partition 1 of the "greetings" topic
greetings.call.from(1).to_a
```

### Using options

Kafka allows reading messages from given offset. Messages are fetched by chunks - you can set a maximum and minimum length (in bytes), as well as the wait time for the server to responce.

This options can be set for a gateway during the [setup phase](#setup):

```ruby
ROM.setup(
  :kafka,
  client_id: :admin,
  min_bytes: 1_024,  # ignore data less then 1Kb
  max_bytes: 10_240, # read nor more than 10Kb at once
  max_wait_ms: 100   # wait for responce no longer than 100ms
)
```

or you can update them with `using` method:

```ruby
# read all messages whatever length they have, and wait for the request up to second
greetings.from(0).using(min_bytes: 1, max_wait_ms: 1_000).call.to_a
```

### Offset

When Kafka reads messages from topic/partition, it stops at some offset. This can be an offset of the last message (at the time of reading).

If in some period of time you'll make another call, it start reading messages from the next offset (only new ones).

```ruby
greetings = rom.relation(:greetings)
greetings.call.to_a
# => [
#      { value: "Hi",    topic: "greetings", key: nil, offset: 0 },
#      { value: "Hello", topic: "greetings", key: nil, offset: 1 }
#    ]
greetings.call.to_a
# => [] (because all messages has bean read diring the first call)
sleep(60)
greetings.call.to_a
# => [
#      { value: "Hola", topic: "greetings", key: nil, offset: 2 }
#    ]
# (only messages being added after the previous call)
```

If you need to restart reading from a specific offset, you can do it by setting `offset` explicitly:

```ruby
rom.relation(:greetings).offset(1).call
# => [
#      { value: "Hello", topic: "greetings", key: nil, offset: 1 },
#    ]
```

You can use info from the last extracted tuple to define an offset, from which to start the next time.

### Limit

You can define a maximum number of messages to return, using the `limit` method:

```ruby
greetings = rom.relation(:greetings)
greetings.offset(1).limit(2).call.to_a
# => [
#      { value: "Hello", topic: "greetings", key: nil, offset: 1 },
#      { value: "Hola",  topic: "greetings", key: nil, offset: 2 }
#    ]
```

But be careful. Actual size of data being read is defined by `:max_bytes` settings, not the offset.

For example, when you set `offset(2)`, the relation can actually fetch the chunk of 5 messages (and move the next offset correspodingly). If you continue reading, you'll miss 3 messages. That's why it is **strongly recommended** to set `offset` explicitly after using of `limit` modifier.

This is unsafe (can cause missing messages):

```ruby
greetings = rom.relation(:greetings).limit(1)
greetings.call.to_a
# => [
#      { value: "Hi",    topic: "greetings", key: nil, offset: 0 },
#    ]
greetings.call.to_a
# => []
```

while this is pretty safe:

```ruby
greetings.limit(1).call.to_a
# => [
#      { value: "Hi",    topic: "greetings", key: nil, offset: 0 },
#    ]
greetings.offset(1).call.to_a
# => [
#      { value: "Hello", topic: "greetings", key: nil, offset: 1 },
#      { value: "Hola",  topic: "greetings", key: nil, offset: 2 }
#    ]
```

Also notice, that every time you use modifier, the new connection is re-established. That's why the **rule of thumb** is either not using modifiers at all, or set the offset explicitly for every call.

## Commands

Kafka supports the `Create` [command only][rom-commands]. You can only add immutable messages to the log, but not to change or delete them.

`ROM::Kafka` provides two helpers for command: `#where` and `#using`.

```ruby
class Greet < ROM::Commands::Create[:kafka]
  relation :greetings
  register_as :greet

  def execute(name)
    super where(key: "foo").using(socket_timeout_ms: 10)
  end
end
```

Here `where` modifier requires only one value for a `:key`. The `using` modifier accepts any value you'll get, but will ignore unused ones. You're recommended to use only [those keys](#additional-options) that are defined for the producer:

- partitioner
- compression_codec
- metadata_refresh_interval_ms
- max_send_retries
- retry_backoff_ms
- required_acks
- ack_timeout_ms
- socket_timeout_ms

In case of success the command returns an array of messages added to Kafka:

```ruby
# After the setup
rom = ROM.finalize.env
greet = rom.command(:greetings).greet

greet.call "Hi, Joe", "How're you?"
# => [
#      { value: "Hi, Joe",     topic: "greetings", key: 0 },
#      { value: "How're you?", topic: "greetings", key: 0 }
#    ]
```

Because producer and consumer connection to Kafka brokers are separated. That's why a command actually not reading messages and knows nothing about their partition and offset (defined by server). You have to read them explicitly if you need (but do you?).

## Mappers

Mappers can be applied to relations and commands in a [standard ROM way][rom-mappers].

[kafka]: http://kafka.apache.org/
[poseidon]: https://github.com/bpot/poseidon
[rom-commands]: http://rom-rb.org/guides/basics/commands/
[rom-github]: https://github.com/rom-rb/rom
[rom-gitter]: https://gitter.im/rom-rb/chat
[rom-kafka]: https://github.com/rom-rb/rom-kafka
[rom-mappers]: http://rom-rb.org/guides/basics/mappers
[rom-relations]: http://rom-rb.org/guides/basics/relations/
[rom-setup]: http://rom-rb.org/guides/basics/setup
[snappy]: https://github.com/miyucy/snappy
