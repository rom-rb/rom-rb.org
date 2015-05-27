Mappers
=======

* [Purpose](#purpose)
* [Basic Usage](#basic-usage)
* [Mapping Strategies](#mapping-strategies)
  - [Lean Interface to Domain](#lean-interface-to-domain)
  - [Rich Interface to Domain](#rich-interface-to-domain)
* [Defining and Applying Mappers](#defining-and-applying-mappers)
  - [Defining a Mapper](#defining-a-mapper)
  - [Data Transformations](#data-transformations)
  - [Applying Mappers](#applying-mappers)
* [Reusing Mappers](#reusing-mappers)
  - [Chaining Mappers to Pipeline](#chaining-mappers-to-pipeline)
  - [Subclassing Mappers](#subclassing-mappers)
  - [Applying Mappers to Nested Data](#applying-mappers-to-nested-data)
* [Arbitrary Mappers](#arbitrary-mappers)

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

With the datastore [relations](relations.md) raw data are extracted from datasets and presented in a form of tuples.

```ruby
users = ROM.env.relation(:users)
users.to_a
# [
#   { id: 1, name: 'jane', email: 'jane@doo.org' },
#   { id: 2, name: 'john', email: 'john@doo.org' }
# ]
```

Mappers allow to convert tuples to the form, required by the domain.

At first define the mapper for a relation.

```ruby
class UserAsEntity < ROM::Mapper
  register_as :entity # the registered name of the mapper
  relation :users     # the name of the relation the mapper is applicable to
  model User          # the domain model to map tuples to
end
```

After [finalization](setup.md) apply the mapper:

```ruby
users.as(:entity).to_a
# [
#   <User @id=1, @name='jane', @email='jane@doo.org'>,
#   <User @id=2, @name='john', @email='john@doo.org'>
# ]

# The same result with the `map_with` alias method
users.map_with(:entity).to_a
```

Mappers can also convert tuples returned by ROM commands.

```ruby
create_user = ROM.env.command(:users).create
create_user.call id: 3, name: 'jack', email: 'jack@doo.org'
# { id: 3, name: 'jack', email: 'jack@doo.org' }

create_user.as(:entity).create id: 4, name: 'joffrey', email: 'joffrey@doo.org'
# <User @id=4, @name='jeff', @email='joffrey@doo.org'>
```

Mapping Strategies
------------------

Consider another example, where the relation contains flat data, that should be mapped into nested models.

```ruby
users_with_roles = ROM.env.relation(:users).with_roles
users_with_roles.to_a
# [
#   { name: 'jane', role: 'admin' },
#   { name: 'jane', role: 'user'  },
#   { name: 'john', role: 'user'  }
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
#   { name: 'jane', roles: [{ title: 'admin' }, { title: 'user' }] },
#   { name: 'john', roles: [{ title: 'user' }] }
# ]
```

Domain entities are responsible for instantiating their objects from mapper-provided hashes.

```ruby
require 'virtus'

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
# <User @name='jane', @roles=[<Role @title='admin'>, <Role @title='user'>]>
john = User.new options.last
# <User @name='john', @roles=[<Role @title='user'>]>
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
#   <User @name='jane', @roles=[<Role @title='admin'>, <Role @title='user'>]>,
#   <User @name='john', @roles=[<Role @title='user'>]>
# ]
```

This flexibility can simplify your domain layer quite a bit. You can design your domain objects exactly the way you want and configure mappings accordingly.

Defining and Applying Mappers
-----------------------------

### Defining a Mapper

Like relations, mappers to be added to ROM environment during the [setup process](setup.md). You're free to declare relations and mappers in any suitable order between invocations of `ROM.setup` and `ROM.finalize`.

```ruby
setup = ROM.setup :memory

# This is when mappers should be registered in a sequence of loading

rom = ROM.finalize.env
```

To register a mapper you can follow any of two styles, that are analogous to the difference between Sinatra’s routing DSL and its modular application style.

In the "routing-style" DSL use the `setup.mappers` for adding a mapper:

```ruby
setup.mappers do
  define(:users) do
    register_as :entity

    model User
  end
end
```

In larger apps, we recommend configuring ROM with explicit class definitions. To do this you should explicitly inherit your mapper from `ROM::Mapper` base class. The following example does the same work as the previous one.

```ruby
class EntityMapper < ROM::Mapper
  register_as :entity
  relation :users

  model User
end
```

As shown above, when defining a new mapper you need to set the registered name of the mapper and the name of the relation it is applicable to. The registered name of the mapper should be unique in a scope of the relation, so the following declarations are correct.

```ruby
class UserEntityMapper < ROM::Mapper
  register_as :entity
  relation :users

  model User
end

class TaskEntityMapper < ROM::Mapper
  register_as :entity
  relation :tasks

  model Task
end
```

### Data Transformations

ROM mapper provides rich DSL with whole bunch of methods to transform source tuples into output hashes/models.
Below is a short list of examples for available transformations. For more details follow a corresponding link.

[Filtering Attributes](mappers/filtering.md)

```ruby
class UsersMapper < ROM::Mapper
  reject_keys
  attribute :id
  attribute :name
end

users.first
# { id: 1, name: 'Joe', email: 'joe@example.com' }

users.as(:users).first
# { id: 1, name: 'Joe' }
```

[Renaming Attributes](mappers/renaming.md)

```ruby
class UsersMapper < ROM::Mapper
  symbolize_keys
  attribute :login, from: :email
end

users.first
# { 'id' => 1, 'name' => 'Joe', 'email' => 'joe@example.com' }

users.as(:users).first
# { id: 1, name: 'Joe', login: 'joe@example.com' }
```

[Wrapping Attributes](mappers/wrapping.md)

```ruby
class UsersMapper < ROM::Mapper
  wrap contacts: [:email, :skype]
end

users.first
# { id: 1, name: 'Joe', email: 'joe@example.com', skype:'joe' }

users.as(:users).first
# { id: 1, name: 'Joe', contacts: { email: 'joe@example.com', skype: 'joe' } }
```

[Unwrapping Tuples](mappers/unwrapping.md)

```ruby
class UsersMapper < ROM::Mapper
  unwrap contacts: [:email]
end

users.first
# { id: 1, name: 'Joe', contacts: { email: 'joe@example.com', skype: 'joe' } }

users.as(:users).first
# { id: 1, name: 'Joe', email: 'joe@example.com', contacts: { skype:'joe' } }
```

[Grouping Tuples](mappers/grouping.md)

```ruby
class UsersMapper < ROM::Mapper
  group contacts: [:email]
end

users.to_a
# [
#   { id: 1, name: 'Joe', email: 'joe@example.com' },
#   { id: 1, name: 'Joe', email: 'joe@doe.org' }
# ]

users.as(:users).to_a
# [
#   {
#     id: 1, name: 'Joe', contacts: [
#       { email: 'joe@example.com' },
#       { email: 'joe@doe.org' }
#     ]
#   }
# ]
```

[Splitting Nested Attributes](mappers/splitting.md)

```ruby
class UsersMapper < ROM::Mapper
  ungroup contacts: [:type]
end

users.to_a
# [
#   {
#     id: 1, name: 'Joe', contacts: [
#       { email: 'joe@example.com',  type: 'home' },
#       { email: 'joe@personal.org', type: 'home' },
#       { email: 'joe@doe.org',      type: 'job'  }
#     ]
#   }
# ]

users.as(:users).to_a
# [
#   {
#     id: 1, name: 'Joe', type: 'home', contacts: [
#       { email: 'joe@example.com' },
#       { email: 'joe@personal.org' }
#     ]
#   }
#   { id: 1, name: 'Joe', type: 'job', contacts: [{ email: 'joe@doe.org' }]
# ]
```

[Combining Relations](mappers/combining.md)

```ruby
class UsersMapper < ROM::Mapper
  combine :roles, on: { name: :name } do
    attribute :role
  end
end

users.to_a
# [{ id: 1, name: 'Joe' }]

roles.to_a
# [{ name: 'Joe', role: 'admin' }, { name: 'Joe', role: 'manager' }]

users.as(:users).to_a
# [{ id: 1, roles: [{ role: 'admin' }, { role: 'manager' }] }]
```

[Mapping Tuples to Models](mappers/models.md)

```ruby
class UserMapepr < ROM::Mapper
  model User
end

users.to_a
# [{ id: 1, name: 'Joe' }]

users.as(:users).to_a
# [#<User @id=1, @name='Joe'>]
```

### Applying a Mapper

After finalizing ROM, apply the mapper to a relation with the `as` method, or its alias `map_with`, using the registered name of the mapper:

```ruby
users = ROM.env.relation(:users) # returns lazy relation
users.first # returns the first record from the raw data
# => { id: 1, name: 'Joe' }

users.as(:entity).first # the record mapped to the User model
# => #<User @id=1, @name='Joe'>

users.map_with(:entity).first # the alternative syntax
```

Like [relations](relations.md#lazy-relations), **mappers are applied lazily** which allows you to compose relations and mappers together in an arbitrary order in the data pipeline. All the following definitions do the same thing:

```ruby
users.with_tasks.with_tags.as(:entity)
users.with_tasks.as(:entity).with_tags
users.as(:entity).with_tasks.with_tags
```

Reusing Mappers
---------------

### The Data Pipeline

Mappers can be applied to source data one-by-one. This is especially useful when you map data from various sources with different data structure. With the help of chaining you can adopt sources to common interface with adapter-specific mappers, and then apply the adapter-agnostic mapper to their outputs.

```
db adapter -> relation(:users) -> mappers(:adapter_specific) -> mappers(:adapter_agnostic) -> domain
```

To do this you can list mappers as arguments of `as` (or `map_with`) method in the required order:

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

users = ROM.finalize.env.relation(:users)

users.first # the raw data
# { id: 1, name: 'Joe', email: 'joe@example.com', skype: 'joe' }

users.as(:nested).first
# { id: 1, name: 'Joe', contacts: { email: 'joe@example.com', skype: 'joe' } }

users.as(:nested, :entity).first
# #<User @id=1, @name='Joe' @contacts={ email: 'joe@example.com', skype: 'joe' }>
```

### Subclassing Mappers

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
# { id: 1, name: 'Joe', contact_email: 'joe@email.com', contact_skype: 'joe' }
users.as(:first).first
# { id: 1, name: 'Joe', email: 'joe@email.com', contact_skype: 'joe' }
users.as(:second).first
# { id: 1, name: 'Joe', email: 'joe@email.com', skype: 'joe' }
```

Use this feature with care. There are [some edge cases you should take into account](mappers/reusing.md).

### Applying Mappers to Nested Data

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
# { id: 1, name: 'Joe', contact_email: 'joe@email.com', contact_skype: 'joe' }
rom.relation(:users).as(:nested_hash).first
# { id: 1, name: 'Joe', contacts: { email: 'joe@email.com', skype: 'joe' } }
```

With this feature you can *extract* common transformations, and share them between various mappers.

Use it with some care! There are [edge cases you should take into account](mappers/wrapping.md#applying-another-mapper).

Arbitrary Mappers
-----------------

ROM allows to register arbitrary coercer object as a mapper. Every object, that responds to `#call` method with one argument can be registered as the ROM mapper.

To register an arbitrary mapper, use the following syntax:

```ruby
arbitrary_mapper = -> users { users.select { |tuple| tuple[:id].to_i < 3 } }

setup.mappers do
  register(:users, external: arbitrary_mapper)
end
```

The mapper will be applied to the whole output of a corresponding relation:

```ruby
users = ROM.env.relation(:users)
users.to_a
# => [{ id: 1, name: 'Jane' }, { id: 2, name: 'Joe' }, { id: 3, name: 'John'}]

users.as(:external).to_a
# => [{ id: 1, name: 'Jane' }, { id: 2, name: 'Joe' }]
```
