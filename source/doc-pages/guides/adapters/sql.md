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

TODO

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
