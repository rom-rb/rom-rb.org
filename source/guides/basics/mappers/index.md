Mappers
=======

* [Purpose](#purpose)
* [Basic Usage](#base-usage)
* [Mapping Strategies](#mapping-strategies)
* [Transformations](#transformations)
* [Reusable Mappers](#reusable-mappers)
* [High-level and Low-level API](#high-level-and-low-level-api)

Purpose
-------

Every application needs different representations of the same data.
Taking data from one representation and converting it into another in ROM
is done by using mappers.

A mapper is an object that takes a tuple and turns it into a [domain object](),
or into a [nested hash](), compatible to domain interface.

ROM provides a DSL to define mappers which can be integrated
with 3rd-party libraries.

Mapping is an extremely powerful concept. It can:

* Rename, wrap and group attributes
* Coerce values
* Build aggregate objects
* Build immutable value objects

ROM also allows you to define mappers that can be reused for many relations.

Basic Usage
--------

With the datastore [relations](../relations/index.md) raw data are extracted
from datasets and presented in a form of tuples:

```ruby
users = ROM.env.relation(:users)
users.to_a
# [
#   { id: 1, name: "jane", email: "jane@doo.org" },
#   { id: 2, name: "john", email: "john@doo.org" }
# ]
```

Mappers allows to convert tuples to the form, required by the domain.

First define the mapper for a relation:

```ruby
class UserMapper < ROM::Mapper
  register_as :item # the registered name of the mapper
  relation :users   # the name of the relation the mapper is applicable to

  model User        # the domain model to map tuples to

  reject_keys       # whitelisting attributes that will be mapped
  attribute :name
end
```

After [finalization]() apply the mapper lazily to a relation with the `as`
method and the registered name of the mapper:

```ruby
users_with_roles.as(:item).to_a
# [
#   <User @id=1, @name="jane", @email="jane@doo.org">,
#   <User @id=2, @name="john", @email="john@doo.org">
# ]
```

Mappers can also convert tuples returned by ROM commands:

```ruby
create_user = ROM.env.command(:users).create
create_user.call id: 3, name: "jack", email: "jack@doo.org"
# { id: 3, name: "jack", email: "jack@doo.org" }

create_user.as(:item).create id: 4, name: "joffrey", email: "joffrey@doo.org"
# <User @id=4, @name="jeff", @email="joffrey@doo.org">
```

Mapping Strategies
------------------

Consider another example, where the relation contains flat data,
that should be mapped into nested models:

```ruby
users_with_roles = ROM.env.relation(:users).with_roles
users_with_roles.to_a
# [
#   { name: "jane", role: "admin" },
#   { name: "jane", role: "user"  },
#   { name: "john", role: "user"  }
# ]
```

Suppose we need to adopt it to list of domain users who each have many roles.
There are two main strategies for doing this.

### 1. Lean Interface to Domain

Under the first approach, the responsibility of the datastore is limited.
It should provide query result as array of hashes, recognizable by the domain.

In this case the datastore is completely decoupled from the domain layer.
It knows nothing about entities and their constructors.

```ruby
class UserAsHash < ROM::Mapper
  register_as :hash
  relation :users

  attribute :name
  group :roles do
    attribute :title, from: :role
  end
end
```

The mapper then converts tuples to entity-friendly hashes:

```ruby
options = users_with_roles.as(:hash).to_a
# [
#   { name: "jane", roles: [{ title: "admin" }, { title: "user" }] },
#   { name: "john", roles: [{ title: "user" }] }
# ]
```

Domain entities are responsible for instantiating their objects
from mapper-provided hashes:

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

Under this second approach, the datastore provides query results
as an array of pre-initialized domain objects.

By defining a mapper, you are specifying which entity class
is going to be instantiated and what attributes are going to be used.

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

Entity classes can be flat objects or aggregates defined separately
from each other (depending on what you need).

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

With the mapper, the datastore adopts tuples directly to domain objects:

```ruby
options = users_with_roles.as(:entity).to_a
# [
#   <User @name="jane", @roles=[<Role @title="admin">, <Role @title="user">]>,
#   <User @name="john", @roles=[<Role @title="user">]>
# ]
```

This flexibility can simplify your domain layer quite a bit.
You can design your domain objects exactly the way you want
and configure mappings accordingly.

Transformations
---------------

By its very nature, ROM mapper provides a set of transformations of source tuples
into output hashes/models.

* [Filtering Attributes](filter.md) # @todo: reject_keys, attribute, embedded, exclude
* [Renaming Attributes](rename.md)  # @todo: attribute, prefix, prefix_separator, symbolize_keys
* [Wrapping Attributes](wrap.md)    # @todo: wrap, unwrap
* [Grouping Tuples](group.md)       # @todo: group
* [Combining Relations](combine.md) # @todo: combine
* [Instantiating Models](models.md) # @todo: model, attribute

Reusing Mappers
---------------

@todo

High-level and Low-level API
----------------------------

@todo:
* Describe two APIs for mappers
* Describe structure of the mapper
* Note naming conventions for relation
