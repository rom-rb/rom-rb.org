---
title: SQL
chapter: Schemas
---

The SQL adapter adds its own schema types and association declarations to the
built-in [Relation Schema](/learn/core/schemas) feature.

## Setting `dataset` through Schema

If your relation class name doesn't match the table name, you can override it
using `schema` API:

``` ruby
module MyApp
  module Relations
    class Users < ROM::Relation[:sql]
      schema(:users, infer: true) # has the same effect as calling `dataset :users`
    end
  end
end
```

## Inferring Attributes

If you don't want to declare all attributes explicitly, you can tell rom-sql to
infer attributes from an existing schema.

Inference will define normal attributes, foreign keys and primary key (even when
it's a composite primary key).

To infer a schema automatically:

``` ruby
require 'rom-sql'

class Users < ROM::Relation[:sql]
  schema(infer: true) # that's it
end
```

## PostgreSQL Types

When you define relation schema attributes using custom PG types, the values
will be automatically coerced before executing commands, so you don't have to
handle that yourself.

``` ruby
require 'rom-sql'
require 'rom/sql/types/pg'

class Users < ROM::Relation[:sql]
  schema do
    attribute :meta, Types::PG::JSON
    attribute :tags, Types::PG::Array
    attribute :info, Types::PG::Hash
  end
end

Users.schema[:meta][{ name: 'Jane' }].class
# Sequel::Postgres::JSONHash

Users.schema[:meta][[1, 2, 3]].class
# Sequel::Postgres::JSONArray

Users.schema[:tags][%w(red green blue)].class
# Sequel::Postgres::JSONArray

Users.schema[:info][{ some: 'info' }].class
# Sequel::Postgres::JSONHash
```
