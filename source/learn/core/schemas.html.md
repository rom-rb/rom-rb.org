---
title: Core
chapter: Schemas
---

Relation schemas define explicitly attribute names and types for tuples that
a given relation provides. All adapters support relation schemas, and adapter-specific
extensions can be provided as well, for example `rom-sql` extends schema DSL with
support for defining associations.

Apart from adapter-specific extensions, schemas can be *extended by you* since
you can define your own *types*. That's how `rom-sql` provides its own PostgreSQL
types.

#### Defining a schema

The DSL is very simple, you provide attribute names along with their types:

``` ruby
class Users < ROM::Relation[:http]
  schema do
    attribute :id, Types::Int
    attribute :name, Types::String
    attribute :age, Types::Int
  end
end
```

#### Commands & Schemas

If you define a schema for a relation, its commands will automatically use it
when processing the input. This allows us to perform database-specific coercions,
setting default values or optionally applying low-level constraints.

Let's say our setup requires generating a UUID prior executing a command:

``` ruby
class Users < ROM::Relation[:http]
  UUID = Types::String.default { SecureRandom.uuid }

  schema do
    attribute :id, UUID
    attribute :name, Types::String
    attribute :age, Types::Int
  end
end
```

Now when you persist data using [repositories](/learn/repositories) or
[custom commands](/learn/advanced/custom-commands), your schema will be used
to process the input data, and our `:id` value will be handled by the `UUID` type.

#### Type System

Schemas use a type system from [dry-types](http://dry-rb.org/gems/dry-types) and
you can define your own schema types however you want. What types you need really
depends on your application requirements, the adapter you're using, specific use cases
of your application and so on.

Here are a couple of guidelines that should help you in making right decisions:

* Don't treat relation schemas as a complex coercion system that is used against
  data received at the HTTP boundary (ie rack request params)
* Coercion logic in schemas should be low-level, ie `Hash` => `PGHash` in `rom-sql`
* Default values should be used as a low-level guarantee that some value is
  **always set** before making a change in your database. Generating a unique id
  is a good example. For default values that are closer to your application domain
  it's better to handle this outside of the persistence layer. In example setting
  `draft` as the default value for post's `:status` attribute is part of your domain
  more than it is part of your persistence layer.
* Strict types *can be used* and they will raise `TypeError` when invalid data
  was accidentely passed to a command. Use this with caution, typically you want
  to validate the data prior sending them to a command, but there might be use cases
  where you expect data to be valid already, and any type error *is indeed an exception*
  and you want your system to crash
