# SQL Adapter

ROM supports SQL databases via `rom-sql` adapter which currently uses [Sequel](#)
under the hood. The adapter ships with an enhanced `Relation` that supports
sql-specific query DSL and association macros that simplify constructing joins.

TODO: probably needs a bit more words

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

## Create

TODO

## Update

TODO

## Delete

TODO

## Transactions

TODO

## Migrations

TODO
