# Cassandra Adapter

[Apache Cassandra]: https://cassandra.apache.org/
[CQL builder BATCH wiki page]: https://github.com/nepalez/query_builder/wiki/BATCH
[CQL builder DELETE wiki page]: https://github.com/nepalez/query_builder/wiki/DELETE
[CQL builder INSERT wiki page]: https://github.com/nepalez/query_builder/wiki/INSERT
[CQL builder SELECT wiki page]: https://github.com/nepalez/query_builder/wiki/SELECT
[CQL builder UPDATE wiki page]: https://github.com/nepalez/query_builder/wiki/UPDATE
[CQL builder wiki]: https://github.com/nepalez/query_builder/wiki/Home
[CQL builder]: https://github.com/nepalez/query_builder
[ROM chatroom]: https://gitter.im/rom-rb/chat
[ROM project on Github]: https://github.com/rom-rb/rom
[rom-cassandra]: https://github.com/rom-rb/rom-cassandra
[ruby driver]: https://github.com/datastax/ruby-driver

ROM supports [Apache Cassandra] via [rom-cassandra] adapter based on Datastax official [ruby driver] and [CQL builder].

- [Setup](#setup)
- [Defining Relations](#defining-relations)
- [Combining Relations](#combining-relations)
- [Commands](#commands)
- [Migrations](#migrations)

*The adapter is still in beta. If you find any inconsistency, please feel free to ask your questions at the [ROM chatroom] and report issues to the [ROM project on Github].*

## Setup

To setup a Cassandra gateway you can use options (if needed):

```ruby
# without options (connects to host '127.0.0.1', port 9042 by default)
ROM.setup(:cassandra)

# with inline host and port
ROM.setup(:cassandra, 'https://127.0.0.1:9042')

# with detail options
ROM.setup(:cassandra, hosts: ['127.0.0.1', '127.0.0.2'], port: 9042, user: 'admin', password: 'foobar')

# multi-gateway setup
ROM.setup(
  default: [:cassandra, hosts: ['127.0.0.1'], port: 9042, user: 'admin', passowrd: 'foobar'],
  other: [:cassandra, hosts: ['https://myserver.com'], port: 9042, user: 'master', password: 'barbaz']
)
```

## Defining Relations

To define a Cassandra relation you can use the standard way of defining relations in ROM. The only specifics is that you're expected to set both keyspace and table name for the dataset in the *dot notation*:

```ruby
class Users < ROM::Relation[:cassandra]
  dataset "authentication.users"
end
```

To define relations that are exposed to you application you can define your own methods and use internal CQL query DSL:

```ruby
class Users < ROM::Relation[:cassandra]
  def last_5_distinct
    distinct.order(:id, :desc).limit(5)
  end

  def by_name(name)
    get(:id, :name).where(name: name)
  end
end
```

Relation methods always return other relations. You can use the following ones:

- `get(*columns)`
- `count(nil|1)`
- `distinct`
- `where(conditions)`
- `where_clustered(options)`
- `order(name, :asc|:desc)`
- `limit(value)`
- `allow_filtering`

See more verbose description of those methods at the [CQL builder SELECT wiki page]. Notice in ROM, the `select(*columns)` is renamed to `get(*columns)`.

## Combining Relations

Both in Cassandra and in ROM there’s no “relationship” concept.

More common way of building aggregates from relations is to combine relations. The combine interface is a standard feature available in ROM for all adapters so there’s nothing special about it in the Cassandra land:

```ruby
class Roles < ROM::Relation[:cassandra]
  repository "authentication.roles"

  def for_users(users)
    where(user_name: users.map(&:name))
  end
end

class UserMapper < ROM::Mapper
  relation :users
  register_as :user_with_roles

  combine :roles, on: { name: :user_name }
end

users = rom.relation(:users)
roles = rom.relation(:roles)

users.combine(tasks).one
```

## Commands

Cassandra commands support all features of the standard ROM command API. In addition, the Cassandra-specific Batch command is supported.

Unlike SQL, Cassandra doesn't read data in course of writing. That's why every command returns an empty array in case of success. To check the result of writing you need to select records manually via corresponding relation.

### Create

```ruby
class CreateUser < ROM::Commands::Create[:cassandra]
  relation :users
  register_as :create_user

  def execute(name)
    super { insert(name: name).if_not_exists }
  end
end

# After the setup
rom = ROM.finalize.env
rom.command(:users).create_user.call "Joe"
# => []
```

The `Create` command supports DSL methods:

- `insert(data)`
- `if_not_exists`
- `using(options)`

See more verbose description of those methods at the [CQL builder INSERT wiki page].

### Update

```ruby
class UpdateUser < ROM::Commands::Update[:cassandra]
  relation :users
  register_as :update_user

  def execute(id, name)
    super { set(name: name).where(id: id).if_exists }
  end
end

# After the setup
rom = ROM.finalize.env
rom.command(:users).update_user.call 1, "Frank"
# => []
```

The `Update` command supports DSL methods:

- `update(options)`
- `using(options)`
- `where(options)`
- `if(options)`
- `if_exists`

See more verbose description of those methods at the [CQL builder UPDATE wiki page].

### Delete

```ruby
class DeleteUser < ROM::Commands::Delete[:cassandra]
  relation :users
  register_as :delete_user

  def execute(id)
    super { where(id: id).if_exists }
  end
end

# After the setup
rom = ROM.finalize.env
rom.command(:users).delete_user.call 1
# => []
```

The `Delete` command supports DSL methods:

- `delete(*columns)`
- `using(options)`
- `where(options)`
- `if(options)`
- `if_exists`

See more verbose description of those methods at the [CQL builder DELETE wiki page].

### Batch

This command is Cassandra-specific, that's why it is inherited from `ROM::Cassandra::Commands::Batch` directly (there's no such abstract thing as `ROM::Commands::Batch`).

You can create a batch for every existing relation (doesn't matter which one to use), add commands, and then call a batch. The whole batch is executed as a single request to the Cassandra cluster.

You needn't to restrict a batch by commands to the same table or keyspace. Feel free to add commands to as many various keyspaces and tables as necessary.

```ruby
class Batch < ROM::Cassandra::Commands::Batch
  relation :users
end

# ...after the setup
rom = ROM.finalize.env
batch = rom.command(:users).batch

batch.add "DELETE FROM authentication.users WHERE id = 1;"
batch.add "INSERT INTO logs.users (id, text) VALUES (1, 'Record deleted');"
batch.call
```

If you like OOP style, use `batch.keyspace(name)` to start the query. The previous example can be rewritten as:

```ruby
# ...
batch.add batch.keyspace(:authentication).table(:users).delete.where(id: 1)
batch.add batch.keyspace(:logs).table(:users).insert(id: 1, text: "Record deleted")
batch.call
```

You can also redefine `execute` method just in the same way as for other commands:

```ruby
class Batch < ROM::Cassandra::Commands::Batch
  relation :users

  def execute(id)
    super {
      self
        .add(keyspace(:authentication).table(:users).delete.where(id: 1))
        .add("INSERT INTO logs.users (id, text) VALUES (1, 'Record deleted');")
    }
  end
end
```

## Migrations

### Writing a Migration

Include into your rakefile:

```ruby
require "rom/cassandra/tasks"
```

Then you can run the task from the command like to scaffold new migration (the second argument can be skipped, default value is shown below):

```
rake db:create_migration[create_users,db/migrate]
```

Then edit the created file and define `up` and `down` methods by hand. Use methods `call` and `keyspace`:

```ruby
# db/migrate/20151231235959_create_users.rb
class CreateUsers < ROM::Cassandra::Migrations::Migration
  def up
    call keyspace(:authentication)
      .create
      .if_not_exists
      .with(options: { class: :SimpleStrategy, replication_factor: 3 })

    call keyspace(:authentication)
      .table(:users)
      .create
      .add(:id, :int)
      .add(:name, :text)
      .primary_key(:id)
      .if_not_exists
  end

  def down
    call keyspace(:authentication).drop.if_exists
  end
end
```

Just like in `Batch` command, you can send either `OOP` queries, or raw CQL statements:

```ruby
# ...
def down
  call "DROP KEYSPACE IF EXISTS authentication.users;"
end
```

You can use many various CQL queries, not only keyspace and table creators.
See the list of queries and available OOP syntax in the [CQL builder wiki].

### Gateway Migration Interface

You can migrate (up|down) to the target version using gateway's low-level interface:

``` ruby
ROM.setup(:cassandra, "127.0.0.1:9042")

gateway = ROM.finalize.env.gateways[:default]

# Default path and logger are shown explicitly.
# You can either skip this settings, or use custom ones.
logger = ROM::Cassandra::Migrations::Logger.new
gateway.migrate path: "db/migrate", logger: logger, version: 20151231235959
```
