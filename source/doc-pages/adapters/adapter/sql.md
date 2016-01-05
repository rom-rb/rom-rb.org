# SQL Adapter

ROM supports SQL databases via `rom-sql` adapter which currently uses [Sequel](http://sequel.jeremyevans.net/)
under the hood. The adapter ships with an enhanced `Relation` that supports
sql-specific query DSL and association macros that simplify constructing joins.

## Setup

To setup an SQL gateway you can use a database URL and options (if needed):

``` ruby
# without options
ROM.setup(:sql, 'sqlite:///path/to/db.sqlite')

# with options
ROM.setup(:sql, 'postgres://localhost/rom', encoding: 'unicode')

# multi-gateway setup
ROM.setup(
  default: [:sql, 'postgres://localhost/default'],
  other: [:sql, 'mysql://localhost/other']
)
```

Following schemes are supported:

- ado
- amalgalite
- cubrid
- db2
- dbi
- do
- fdbsql
- firebird
- ibmdb
- informix
- jdbc
- mysql
- mysql2
- odbc
- openbase
- oracle
- postgres
- sqlanywhere
- sqlite
- swift
- tinytds

## Defining Relations

To define an SQL relation you can use the standard way of defining relations in ROM:

``` ruby
class Users < ROM::Relation[:sql]
end
```

By default relation's `dataset` name is inferred from the class name. You can
override this easily:

``` ruby
module Relations
  class Users < ROM::Relation[:sql]
    dataset :users
  end
end
```

To define relations that are exposed to you application you can define your own
methods and use internal [query DSL](#):

``` ruby
class Users < ROM::Relation[:sql]
  def by_id(id)
    where(id: id)
  end
end
```

Remember that relation methods must always return other relations, you shouldn't
return a single tuple.

## Associations

In ROM there's no "relationship" concept, instead you simply use relation interface
to load data like you want.

### Using Joins

To load associated relations you can simply use `inner_join` or `left_join`:

``` ruby
class Users < ROM::Relation[:sql]
  def with_tasks
    inner_join(:tasks, user_id: :id)
  end

  def with_posts
    left_join(:posts, user_id: :id)
  end
end

rom.relation(:users).with_tasks
rom.relation(:users).with_posts
```

### Qualifying And Renaming Attributes

Joining relations introduces a problem of having conflicting attribute names. To
solve this you often need to qualify and rename columns.

To qualify all attributes in a relation:

``` ruby
class Users < ROM::Relation[:sql]
  def with_tasks
    qualified.inner_join(:tasks, user_id: :id)
  end
  # produces "SELECT users.id, users.name ..."
end
```

To rename all attributes in a relation:

``` ruby
class Users < ROM::Relation[:sql]
  def with_tasks
    prefix(:user).qualified.inner_join(:tasks, user_id: :id)
  end
  # produces "SELECT users.id AS user_id, users.name AS user_name ..."
end
```

### Using Renamed Attributes in GROUP or WHERE Clauses

If attributes need to be qualified and you want to use them in `group` or `where`
you can use special syntax with double-underscore:

``` ruby
class Users < ROM::Relation[:sql]
  def with_tasks
    prefix(:user).qualified.inner_join(:tasks, user_id: :id)
      .where(users__name: 'Jane')
  end
  # produces "SELECT ... FROM ... WHERE users.name = 'Jane'"
end
```

### Mapping Joined Relations

You can map a result from a join to a single aggregate using mappers:

``` ruby
class Users < ROM::Relation[:sql]
  def with_tasks
    joinable
      .inner_join(:tasks, user_id: :id)
      .select_append(:tasks__title)
  end

  def joinable
    prefix(:user).qualified
  end
end

class UserMapper < ROM::Mapper
  relation :users
  register_as :user_with_tasks

  prefix :user

  attribute :id
  attribute :name

  group :tasks do
    attribute :title
  end
end

rom.relation(:users).as(:user_with_tasks).with_tasks.one
```

This technique is brittle as it requires careful selection of the attributes and
dealing with potential name conflicts; however, for performance reasons you may
have cases where you would prefer to use joins.

Here ROM doesn't block you and gives you all that's needed to map complex join
results into a simple domain aggregate.

### Combining Relations

More common way of building aggregates from relations is to combine relations.
This is a very powerful and flexible technique that results in a small amount
of queries and fast mapping to domain aggregates.

The `combine` interface is a standard feature available in ROM for all adapters
so there's nothing special about it in the SQL land:

``` ruby
class Tasks < ROM::Relation[:sql]
  def for_users(users)
    where(user_id: users.map { |u| u[:id] })
  end
end

class UserMapper < ROM::Mapper
  relation :users
  register_as :user_with_tasks

  combine :tasks, on: { id: :user_id }
end

users = rom.relation(:users)
tasks = rom.relation(:tasks)

users.combine(tasks).one
```

## Commands

SQL commands support all features of the standard [ROM command API](/guides/basics/commands/). In addition, the following SQL-specific features are supported:

- The `associates` plugin, for connecting foreign key values when composing commands
- The `transaction` interface, which provides a block scope for working with database transactions

### Associates Plugin

The `associates` plugin is used to automatically set foreign-key values when using
command composition.

``` ruby
class CreateTask < ROM::Commands::Create[:sql]
  relation :tasks
  register_as :create
  result :one

  associates :user, key: [:user_id, :id]
end

class CreateUser < ROM::Commands::Create[:sql]
  relation :users
  register_as :create
  result :one
end

# using command composition
create_user = rom.command(:users).create
create_task = rom.command(:tasks).create

command = create_user.with(name: 'Jane') >> create_task.with(title: 'Task')
command.call

# using a graph
command = rom.command([
  { user: :users }, [:create, [{ task: :tasks }, [:create]]]
])

command.call user: { name: 'Jane', task: { title: 'Task' } }
```

### Transactions

To use a transaction simple wrap calling a command inside its transaction block:

``` ruby
class CreateTask < ROM::Commands::Create[:sql]
  relation :tasks
  register_as :create
  result :one

  associates :user, key: [:user_id, :id]
end

class CreateUser < ROM::Commands::Create[:sql]
  relation :users
  register_as :create
  result :one
end

# using command composition
create_user = rom.command(:users).create
create_task = rom.command(:tasks).create

command = create_user.with(name: 'Jane') >> create_task.with(title: 'Task')

# rollback happens when any error is raised ie a CommandError from a validator
command.transaction do
  command.call
end

# manual rollback
create_user.transaction do
  user = create_user.call(name: 'Jane')

  if all_good?
    task = create_task.with(title: 'Jane').call(user)
  else
    raise ROM::SQL::Rollback
  end
end
```

## Migrations

There are migration tasks available and migration interface available in SQL
gateways.

### Using Rake Tasks

To load migration tasks simply require them and provide `db:setup` task which
sets up ROM.

``` ruby
# your rakefile

require 'rom/sql/rake_task'

namespace :db do
  task :setup do
    # your ROM setup code
  end
end
```

Following tasks are available:

* `rake db:create_migration[create_users]` - create migration file under `db/migrations`
* `rake db:migrate` - runs migrations
* `rake db:clean` - removes all tables
* `rake db:reset` - removes all tables and re-runs migrations

### Using Gateway Migration Interface

You can use migrations using gateway's interface:

``` ruby
ROM.setup(:sql, 'postgres://localhost/rom')

gateway = ROM.finalize.env.gateways[:default]

migration = gateway.migration do
  change do
    create_table :users do
      primary_key :id
      column :name, String, null: false
    end
  end
end

migration.apply(gateway.connection, :up)
```
