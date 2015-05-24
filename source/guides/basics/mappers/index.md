Mappers
=======

* [Purpose](#purpose)
* [Basic Usage](#basic-usage)
* [Mapping Strategies](#mapping-strategies)
* [Transformations](#transformations)
* [Reusing Mappers](#reusing-mappers)
* [Arbitrary Mappers](#arbitrary-mappers)
* [High-level and Low-level API](#high-level-and-low-level-api)

Purpose
-------

Every application needs different representations of the same data. Taking data from one representation and converting it into another in ROM is done by using mappers.

A mapper is an object that takes a tuple and turns it into a domain object, or nested hash, compatible to domain interface.

ROM provides a DSL to define mappers which can be integrated with 3rd-party libraries.

Mapping is an extremely powerful concept. It can:

* Rename, wrap and group attributes.
* Coerce values.
* Build aggregate objects.
* Build immutable value objects.

ROM also allows you to define mappers that can be reused for many relations.

Basic Usage
-----------

With the datastore [relations](../relations/index.md) raw data are extracted from datasets and presented in a form of tuples.

```ruby
users = ROM.env.relation(:users)
users.to_a
# [
#   { id: 1, name: "jane", email: "jane@doo.org" },
#   { id: 2, name: "john", email: "john@doo.org" }
# ]
```

Mappers allows to convert tuples to the form, required by the domain.

At first define the mapper for a relation.

```ruby
class UserAsEntity < ROM::Mapper
  register_as :entity # the registered name of the mapper
  relation :users     # the name of the relation the mapper is applicable to
  model User          # the domain model to map tuples to
end
```

After [finalization](../setup.md) apply the mapper lazily to a relation with the `as` method (or its alias method `map_with`) and the registered name of the mapper.

```ruby
users.as(:entity).to_a
# [
#   <User @id=1, @name="jane", @email="jane@doo.org">,
#   <User @id=2, @name="john", @email="john@doo.org">
# ]

# The same result with the `map_with` alias method
users.map_with(:entity).to_a
```

Mappers can also convert tuples returned by ROM commands.

```ruby
create_user = ROM.env.command(:users).create
create_user.call id: 3, name: "jack", email: "jack@doo.org"
# { id: 3, name: "jack", email: "jack@doo.org" }

create_user.as(:entity).create id: 4, name: "joffrey", email: "joffrey@doo.org"
# <User @id=4, @name="jeff", @email="joffrey@doo.org">
```

Mapping Strategies
------------------

Consider another example, where the relation contains flat data, that should be mapped into nested models.

```ruby
users_with_roles = ROM.env.relation(:users).with_roles
users_with_roles.to_a
# [
#   { name: "jane", role: "admin" },
#   { name: "jane", role: "user"  },
#   { name: "john", role: "user"  }
# ]
```

Suppose we need to adopt it to list of domain users who each have many roles. There are two main strategies for doing this.

### 1. Lean Interface to Domain

Under the first approach, the responsibility of the datastore is limited. It should provide query result as array of hashes, recognizable by the domain.

In this case the datastore is completely decoupled from the domain layer. It knows nothing about entities and their constructors.
The mapper is responsible for transforming source tuples to entity-friendly hashes.

```ruby
class UserAsHash < ROM::Mapper
  register_as :hash
  relation :users

  attribute :name
  group :roles do
    attribute :title, from: :role
  end
end

options = users_with_roles.as(:hash).to_a
# [
#   { name: "jane", roles: [{ title: "admin" }, { title: "user" }] },
#   { name: "john", roles: [{ title: "user" }] }
# ]
```

Domain entities are responsible for instantiating their objects from mapper-provided hashes.

```ruby
require "virtus"

class Role
  include Virtus.model

  attribute :title, String
end

class User
  include Virtus.model

  attribute :name,  String
  attribute :roles, Array[Role]
end

jane = User.new options.first
# <User @name="jane", @roles=[<Role @title="admin">, <Role @title="user">]>
john = User.new options.last
# <User @name="john", @roles=[<Role @title="user">]>
```

### 2. Rich Interface to Domain

Under this second approach, the datastore provides query results as an array of pre-initialized domain objects.

By defining a mapper, you are specifying which entity class is going to be instantiated and what attributes are going to be used.

```ruby
class UserAsEntity < ROM::Mapper
  register_as :entity
  relation :users

  model User

  attribute :name
  group :roles do
    model Role

    attribute :title, from: :role
  end
end
```

Entity classes can be flat objects or aggregates defined separately from each other (depending on what you need).

```ruby
class User
  include Virtus.model

  attribute :name
  attribute :role # no coersion needed, this work is done by the mapper
end

class Role
  include Virtus.model

  attribute :title
end
```

With the mapper, the datastore adopts tuples directly to domain objects.

```ruby
options = users_with_roles.as(:entity).to_a
# [
#   <User @name="jane", @roles=[<Role @title="admin">, <Role @title="user">]>,
#   <User @name="john", @roles=[<Role @title="user">]>
# ]
```

This flexibility can simplify your domain layer quite a bit. You can design your domain objects exactly the way you want and configure mappings accordingly.

Transformations
---------------

By its very nature, ROM mapper provides a set of transformations of source tuples into output hashes/models.

* [Filtering Attributes](filtering.md)
* [Renaming Attributes](renaming.md)
* [Wrapping Attributes](wrapping.md) and [Unwrapping Tuples](unwrapping.md)
* [Grouping Tuples](grouping.md) and [Splitting Attributes](splitting.md)
* [Combining Relations](combining.md)
* [Mapping Tuples to Models](models.md)

Reusing Mappers
---------------

ROM provides two ways for reusing existing mappers:

* Chaining mappers to pipeline.
* Subclassing Mappers.
* Applying mappers to embedded attributes ([group](grouping.md) and [wrap](wrapping.md)).

### 1. Chaining Mappers to Pipeline

Mappers can be applied to source data one-by-one.

```
db adapter -> relation(:users) -> mappers(:nested) -> mappers(:entity) -> domain
```

Every next mapper will use the output of the previous one as its own input, just in the same way as it were the result of some relation. To do this list the mappers as arguments of `as` (or `map_with`) method call in the required order:

```ruby
class NestingMapper < ROM::Mapper
  register_as :nested
  relation :users

  wrap contacts: [:email, :skype]
end

class EntityMapper < ROM::Mapper
  register_as :entity
  relation :users

  class User
end

rom = ROM.finalize.env
users = rom.relation(:users)

users.first # the raw data
# { id: 1, name: "Joe", email: "joe@example.com", skype: "joe" }
users.as(:nested).first
# { id: 1, name: "Joe", contacts: { email: "joe@example.com", skype: "joe" } }
users.as(:nested, :entity).first
# #<User @id=1, @name="Joe" @contacts={ email: "joe@example.com", skype: "joe" }>
```

This is especially useful when you map data from various sources, including sql database, and non-sql sources like MongoDB.
With the help of chaining you can adopt sources to common interface using an adapter-specific mapper, and then apply the adapter-agnostic mapper to their outputs.

### 2. Subclassing Mappers

To DRY the code you can *subclass* a new mapper from existing one and customize it for slightly different output.

```ruby
class FirstMapper < ROM::Mapper
  register_as :first
  relation :users

  attribute :email, from: :contact_email
end

class SecondMapper < FirstMapper
  register_as :second
  relation :users

  attribute :skype, from: :contact_skype
end

rom = ROM.finalize.env
users = rom.relation(:users)

users.first
# { id: 1, name: "Joe", contact_email: "joe@email.com", contact_skype: "joe" }
users.as(:first).first
# { id: 1, name: "Joe", email: "joe@email.com", contact_skype: "joe" }
users.as(:second).first
# { id: 1, name: "Joe", email: "joe@email.com", skype: "joe" }
```

Use this feature with care. There are [some edge cases you should take into account](reusing.md).

### 3. Applying Mappers to Embedded Attributes

Another way to make the code DRY is to apply reusable mapper to nested group of fields (either `group` or `wrap`).

```ruby
class ContactMapper < ROM::Mapper
  register_as :contact
  relation :users

  attribute :email, from: :contact_email
  attribute :skype, from: :contact_skype
end

class UserMapper < ROM::Mapper
  register_as :nested_hash
  relation :users

  wrap :contacts, mapper: ContactMapper
end

rom = ROM.finalize.env
rom.relation(:users).first
# { id: 1, name: "Joe", contact_email: "joe@email.com", contact_skype: "joe" }
rom.relation(:users).as(:nested_hash).first
# { id: 1, name: "Joe", contacts: { email: "joe@email.com", skype: "joe" } }
```

With this feature you can *extract and share* common transformations between various mappers.

Use it with some care! There is [an edge case you should take into account](wrapping.md#applying-another-mapper).

Arbitrary Mappers
-----------------

ROM allows to register arbitrary coercer object as a mapper.

@todo

High-level and Low-level API
----------------------------

@todo:
* Describe two APIs for mappers
* Describe structure of the mapper
* Note naming conventions for relation
