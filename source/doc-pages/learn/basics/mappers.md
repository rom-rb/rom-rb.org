# Mappers

* [Purpose](#purpose)
* [Basic Usage](#basic-usage)
* [Mapping Strategies](#mapping-strategies)
  - [Lean Interface to Domain](#lean-interface-to-domain)
  - [Rich Interface to Domain](#rich-interface-to-domain)
* [Defining Mappers](#defining-and-using-mappers)
  - [Defining a Mapper](#defining-a-mapper)
  - [Data Transformations](#data-transformations)
  - [Applying Transformations to Embedded Attributes](#applying-transformations-to-embedded-attributes)
  - [Applying Transformations Step by Step](#applying-transformations-step-by-step)
* [Applying and Reusing Mappers](#applying-and-reusing-mappers)
  - [Applying Mappers to Relations](#applying-mappers-to-relations)
  - [Chaining Mappers to Pipeline](#chaining-mappers-to-pipeline)
  - [Subclassing Mappers](#subclassing-mappers)
  - [Applying Mappers to Nested Data](#applying-mappers-to-nested-data)
* [Custom Mappers](#custom-mappers)

## Purpose

Every application needs different representations of the same data. Taking data
from one representation and converting it into another in ROM is done by using
mappers.

Even though [Repository](/guides/basics/repositories/) supports automatic mapping
to structs, you may face situations where a customized mapping logic can be helpful.

Another great use-case for mappers is converting input into persistable form that
matches your database schema, which works great with [commands](/guides/basics/commands).

A mapper is an object that takes a relation and turns it into a domain-specific
collection which can include objects compatible with the domain interface. It can
return plain hashes or instantiate domain-specific models for you.

ROM provides a DSL to define mappers which can be integrated with 3rd-party
libraries.

Mapping is an extremely powerful concept. It can:

* Filter and rename attributes
* Wrap and group attributes
* Coerce values
* Build aggregate objects
* Build immutable value objects
* And more...

ROM also allows you to define mappers that can be reused for many relations, or
combined to create a pipeline.

## Installation

Mappers are part of `rom-mapper` gem which core `rom` gem depends on; however,
you can use mappers standalone, in that case simply install the gem:

``` sh
gem install rom-mapper
```

## Basic Usage

With the adapter [relations](/guides/basics/relations) raw data are extracted
from datasets and presented in a form of tuples.

```ruby
users = ROM.env.relation(:users)
users.to_a
# [
#   { id: 1, name: 'jane', email: 'jane@doo.org' },
#   { id: 2, name: 'john', email: 'john@doo.org' }
# ]
```

Mappers convert tuples into the form required by the domain.

To create a mapper, first define the mapper for a relation.

```ruby
class UserAsEntity < ROM::Mapper
  register_as :entity # the registered name of the mapper
  relation :users     # the name of the relation the mapper is applicable to
  model User          # the domain model to map tuples to
end
```

After [finalization](/guides/basics/setup) apply the mapper on the
dataset. Here we call `map_with` to apply the `UserAsEntity` mapper
(registered as `entity`) on the dataset:

```ruby
users.as(:entity).to_a
# [
#   <User @id=1, @name='jane', @email='jane@doo.org'>,
#   <User @id=2, @name='john', @email='john@doo.org'>
# ]

# The same result with the `map_with` alias method
users.map_with(:entity).to_a
```

Mappers can also convert tuples returned from
[commands](/guides/basics/commands).

```ruby
rom = ROM.env

rom.command(:users).create.call(
  id: 3, name: 'jack', email: 'jack@doo.org'
)
# { id: 3, name: 'jack', email: 'jack@doo.org' }

rom.command(:users).as(:entity).create(
  id: 4, name: 'joffrey', email: 'joffrey@doo.org'
)
# <User @id=4, @name='jeff', @email='joffrey@doo.org'>
```

## Mapping Strategies

Another example which comes up frequently is to map flat data into a nested model.

```ruby
users_with_roles = ROM.env.relation(:users).with_roles
users_with_roles.to_a
# [
#   { name: 'jane', role: 'admin' },
#   { name: 'jane', role: 'user'  },
#   { name: 'john', role: 'user'  }
# ]
```

Suppose we need to convert it to list of domain users who each have many roles. There are two main strategies for doing this.

### 1. Lean Interface to Domain

Under the first approach, the responsibility of the datastore is limited. It should provide query result as array of hashes, recognizable by the domain.

In this case the datastore is completely decoupled from the domain layer. It knows nothing about entities and their constructors.
The mapper is responsible for transforming source tuples to entity-friendly hashes.

In this example we will use the `group` syntax to group user roles.

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
class Role
  include Virtus.model

  attribute :title
end

class User
  include Virtus.model

  attribute :name
  attribute :roles # no coersion is needed here, this work is done by the mapper
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

## Defining and Applying Mappers

### Defining a Mapper

Like relations, mappers to be added to ROM environment during the
[setup process](/guides/basics/setup). You're free to declare
relations and mappers in any suitable order between invocations of
`ROM.setup` and `ROM.finalize`.

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

As shown above, when defining a new mapper you need to set the registered name of the mapper and the name of the relation it is applicable to. The registered name of the mapper should be unique in a scope of the relation, so the following declarations are correct and do not conflict.

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

ROM mapper provides a rich DSL with a number of methods to transform the source into output domain objects. It supports:

* [Filtering Attributes](filtering)
* [Renaming Attributes](renaming)
* [Wrapping Attributes](wrapping)
* [Grouping Tuples](grouping)
* [Folding Tuples](folding)
* [Combining Tuples from Several Relations](combining)
* [Mapping Tuples to Models](models)
* [Embedded Attributes](embedded)

Below are some examples of the available transformations. For more details follow the corresponding link.


#### [Filtering Attributes](filtering)

You can either blacklist attributes:

```ruby
class UsersMapper < ROM::Mapper
  exclude :password
end

users.first
# { id: 1, name: 'Joe', password: '123456' }

users.as(:users).first
# { id: 1, name: 'Joe' }
```

...or whitelist them:

```ruby
class UsersMapper < ROM::Mapper
  reject_keys true # Any keys not declared will be rejected
  attribute :id
  attribute :name
end

users.first
# { id: 1, name: 'Joe', email: 'joe@example.com' }

users.as(:users).first
# { id: 1, name: 'Joe' }
```

#### [Renaming Attributes](renaming)

Attributes can be renamed:

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

#### [Wrapping Attributes](wrapping)
Attributes can be nested inside a new object.

```ruby
class UsersMapper < ROM::Mapper
  wrap :contacts do
    attribute :email
    attribute :skype
  end
end

users.first
# { id: 1, name: 'Joe', email: 'joe@example.com', skype:'joe' }

users.as(:users).first
# { id: 1, name: 'Joe', contacts: { email: 'joe@example.com', skype: 'joe' } }
```

#### [Unwrapping Tuples](unwrapping)
Attributes can be pulled out of a nested object:

```ruby
class UsersMapper < ROM::Mapper
  unwrap :contacts do
    attribute :email
  end
end

users.first
# { id: 1, name: 'Joe', contacts: { email: 'joe@example.com', skype: 'joe' } }

users.as(:users).first
# { id: 1, name: 'Joe', email: 'joe@example.com', contacts: { skype:'joe' } }
```

#### [Grouping Tuples](grouping)
Objects can be grouped on certain attributes:

```ruby
class UsersMapper < ROM::Mapper
  group :contacts do
    attribute :email
  end
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

#### [Ungrouping Attributes](ungrouping)
Objects can be ungrouped resulting in a flattened structure:

```ruby
class UsersMapper < ROM::Mapper
  ungroup :contacts do
    attribute :email
  end
end

users.to_a
# [
#   {
#     id: 1, name: 'Joe', contacts: [
#       { email: 'joe@example.com' },
#       { email: 'joe@doe.org' }
#     ]
#   }
# ]

users.as(:users).to_a
# [
#   { id: 1, name: 'Joe', email: 'joe@example.com' },
#   { id: 1, name: 'Joe', email: 'joe@doe.org' }
# ]
```

#### [Folding Tuples](folding)

```ruby
class UsersMapper < ROM::Mapper
  fold :contacts do
    attribute :email
  end
end

users.to_a
# [
#   { id: 1, name: 'Joe', email: 'joe@example.com' },
#   { id: 1, name: 'Joe', email: 'joe@doe.org' }
# ]

users.as(:users).to_a
# [{ id: 1, name: 'Joe', contacts: ['joe@example.com', 'joe@doe.org'] }]
```

#### [Unfolding Attributes](unfolding)
Objects can be unfolded, resulting in a flattened structure:

```ruby
class UsersMapper < ROM::Mapper
  unfold :email, from: :contacts
end

users.to_a
# [{ id: 1, name: 'Joe', contacts: ['joe@example.com', 'joe@doe.org'] }]

users.as(:users).to_a
# [
#   { id: 1, name: 'Joe', email: 'joe@example.com' },
#   { id: 1, name: 'Joe', email: 'joe@doe.org' }
# ]
```

#### [Combining Tuples from Several Relations](combining)

```ruby
class Roles < ROM::Relation[:memory]
  def for_users(users)
    restrict(user_id: users.map { |u| u[:id] })
  end
end

class UsersMapper < ROM::Mapper
  relation :users
  register_as :with_roles

  combine :roles, on: { id: :user_id } do
    attribute :name, from: :role
  end
end

users.to_a
# [{ id: 1, name: 'Joe' }]

roles.to_a
# [{ user_id: 1, role: 'admin' }, { user_id: 1, role: 'manager' }]

users_with_roles = users.combine(roles.for_users).as(:user_with_roles).to_a
# [{ id: 1, name: 'Joe', roles: [{ name: 'admin' }, { name: 'manager' }] }]
```

#### [Mapping Tuples to Models](models)
The result of a mapping can be a model object, rather than a simple hash or array:

```ruby
class UserMapper < ROM::Mapper
  model User
end

users.to_a
# [{ id: 1, name: 'Joe' }]

users.as(:users).to_a
# [#<User @id=1, @name='Joe'>]
```

#### [Embedded Attributes](embedded)

Suppose we have a source with a deeply nested data to transform:

```ruby
users = ROM.env.relation(:users)
users.first
# {
#   list_id: 1,
#   list_tasks: [
#     { user: 'Jacob', task_id: 1, task_title: 'be nice'    },
#     { user: 'Jacob', task_id: 2, task_title: 'sleep well' }
#   ]
# }
```

With the help of `embedded` we could apply transformations to the necessary level of nesting:

```ruby
class UserMapper < ROM::Mapper
  relation :users
  register_as :users

  embedded :list_tasks, type: :array do
    group :tasks, prefix: 'task' do
      attribute :id
      attribute :title
    end
  end
end

users.as(:users).first
# {
#   list_id: 1,
#   list_tasks: [
#     {
#       user: 'Jacob', tasks: [
#         { id: 1, title: 'be nice' },
#         { id: 2, title: 'sleep well' }
#       ]
#     }
#   ]
# }
```

See [Embedding Transformations](embedding.md) for further details.

### Applying Transformations Step by Step

Various transformations can be applied by mappers step-by-step. This allows a mapper to take deeply nested data from source, rearrange them and provide any required output.

Suppose the relation returns the following data:

```ruby
users = ROM.env.relation(:users)
users.first
# {
#   list_id: 1,
#   list_tasks: [
#     { user: 'Jacob', task_id: 1, task_title: 'be nice'    },
#     { user: 'Jacob', task_id: 2, task_title: 'sleep well' }
#   ]
# }
```

With the sequence of several `step`-s we can perform a series of complex tranformations inside one mapper:

```ruby
class UserMapper < ROM::Mapper
  relation :users
  register_as :users

  step do
    prefix 'list'
    attribute :id
    unfold :tasks
  end

  step do
    unwrap :tasks do
      attribute :task_id
      attribute :name, from: :user
      attribute :task_title
    end
  end

  step do
    group :tasks do
      prefix 'task'
      attribute :id
      attribute :title
    end
  end

  step do
    wrap :user do
      attribute :name
      attribute :tasks
    end
  end
end
```

The mapper will provide the output as following:

```ruby
users.as(:users).first
# {
#   id: 1,
#   user: {
#     name: 'Jacob',
#     tasks: [
#       { id: 1, title: 'be nice'    },
#       { id: 2, title: 'sleep well' }
#     ]
#   }
# }
```

Look at the [corresponding subsection](sequencing) for further details.

Using and Reusing Mappers
----------------------------

### Applying Mappers to Relations

After finalizing ROM, apply the mapper to a relation with the `as` method, or its alias `map_with`, using the registered name of the mapper:

```ruby
users = ROM.env.relation(:users) # returns lazy relation
users.first # returns the first record from the raw data
# => { id: 1, name: 'Joe' }

users.as(:entity).first # the record mapped to the User model
# => #<User @id=1, @name='Joe'>

users.map_with(:entity).first # the alternative syntax
```

Like [relations](/buides/basics/relations#lazy-relations), **mappers are applied lazily** which allows you to compose relations and mappers together in an arbitrary order in the data pipeline. All the following definitions do the same thing:

```ruby
users.with_tasks.with_tags.as(:entity)
users.with_tasks.as(:entity).with_tags
users.as(:entity).with_tasks.with_tags
```

## Reusing Mappers

### The Data Pipeline

Mappers can be applied to source data one-by-one. This is especially useful when you map data from various sources with different data structure. With the help of chaining you can adopt sources to common interface with adapter-specific mappers, and then apply the adapter-agnostic mapper to their outputs.

```
db adapter ->
  relation(:users) ->
    mappers(:adapter_specific) ->
      mappers(:adapter_agnostic) -> domain
```

To do this you can list mappers as arguments of `as` (or `map_with`) method in the required order:

```ruby
class NestingMapper < ROM::Mapper
  register_as :nested
  relation :users

  wrap :contacts do
    attribute :email
    attribute :skype
  end
end

class EntityMapper < ROM::Mapper
  register_as :entity
  relation :users

  model User
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

To keep your code [DRY](http://en.wikipedia.org/wiki/Don%27t_repeat_yourself), mappers can be *subclassed* from existing mappers to customize it for slightly different output.

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

Use this feature with care. There are [some edge cases you should take into account](reusing).

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

Use it with some care! There are [edge cases you should take into account](wrapping#applying-another-mapper).

## Custom Mappers

ROM allows custom coercer objects to be registered as mappers. Any object, that responds to `#call` method with one argument can be registered as a ROM mapper.

To register an arbitrary mapper, use the following syntax:

```ruby
arbitrary_mapper = -> users { users.map { |tuple| tuple[:id] } }

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
# => [1, 2]
```
