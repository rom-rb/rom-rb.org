---
title: Reading Simple Objects
chapter: Reading
---

# Reading Simple Objects

## Relations

Relations are the basis for reading data. Many adapters, like the popular
`rom-sql` support automatically inferring default relations from your datastore
schema. Hooray!

If your chosen adapter doesn't support relation inference, or you want to
override the default, just call `Configuration#relation`.

```ruby
rom_container = ROM.container(:sql, 'sqlite::memory') do |rom|
  rom.use :macros

  rom.relation(:users)

  rom.relation(:tasks) do
    # overriding the default dataset to link the relation to a table of a different name
    dataset :tickets
  end
end
```

Most of the time, though, you'll do reading though a *Repository*.

## Repositories

A Repository ("Repo") object provides a lot of conveniences for reading data
with relations.

You need to explicitly declare which `relations` it can access:

```ruby
require 'rom-repository'

# Assuming a database with table 'users'
rom_container = ROM.container(:sql, 'sqlite::memory')

class MyRepository < ROM::Repository::Base
  relations :users

  # ... selector methods will go here. We'll discuss those later
end

user_repo = MyRepository.new(rom_container)

user_repo.users.to_a
# => []
```

Depending on how complex your application becomes, you may want to create
separate Repository classes to subdivide duties.

```ruby
# Assuming a database with tables 'users' and 'projects'
rom_container = ROM.container(:sql, 'sqlite::memory')

# Perhaps one Repo to handle users and related authentication relations
class UsersRepository < ROM::Repository::Base
  relations :users

  # ... [users-related selector methods go here]
end

# Another repository could handle the projects and related concepts
class ProjectRepository < ROM::Repository::Base
  relations :projects

  # ... [project-related selector methods go here]
end

user_repo = UserRepository.new(rom_container)
project_repo = ProjectRepository.new(rom_container)

# now we can pass both repositories into your app
MyApp.run(user_repo, project_repo)
```

### Selector Methods

While defining a Repository, you will also define its methods for
domain-specific queries. These are called **selector methods**.

They use the querying methods provided by the adapter to accomplish their task.
For example, the `rom-sql` adapter provides methods like `Relation#where`.

```ruby
class MyRepository
  # declaring :users here makes the #users method available
  relations :users

  # find all users with the given attributes
  def users_with(attributes_hash)
    users.where(attributes_hash)
  end

  # collect  a list of all user ids
  def user_id_list
    users.map { |user| user[:id] }
  end
end
```

Read your adapter's documentation to see the full listing of its Relation
methods.

> These are just simple reads. See the [Associations](/learn/associations)
> section to see how to construct multi-relation selector methods using joins.

#### Single Results vs Many Results

Every relation is lazy loading and most methods return another relation. To
materialize the relation and get actual data, use `#one`, `#one!`, or `#to_a`.

```ruby
# Produces a single tuple or nil if none found.
# Raises an error if there are more than one.
users.one

# Produces a single tuple.
# Raises an error if there are 0 results or more than one.
users.one!

# Produces an array of tuples, possibly empty.
users.to_a
```

## Full Example

This short example demonstrates using selector methods, #one, and #to_a.

```ruby
require 'rom-repository'

rom_container = ROM.container(:sql, 'sqlite::memory') do |rom|
  rom.use :macros

  rom.relation(:users)
end

class MyRepository < ROM::Repository::Base
  relations :users # this makes the #users method available

  # selector methods
  def users_with(params)
     users.where(params).to_a
  end

  def user_by_id(id)
     users.where(id: id).one!
  end

  # ... etc
end

MyApp.run(rom_container, MyRepository.new(rom_container))
```

And then in our app we can use the selector methods:

```ruby
# assuming that there is already data present

repository.users_with(first_name: 'Malcolm', last_name: 'Reynolds')
#=> [ROM::Struct[User] , ROM::Struct[User], ...]

repository.user_by_id(1)
#=> ROM::Struct[User]
```

## Mapping To Custom Objects

Repositories can map relations to your custom objects. As a general best-practice
every public repository method should return materialized, domain objects.

> You can use any object type where constructor accepts a hash with attributes.

### Using With dry-data

[dry-data](https://github.com/dryrb/dry-data) provides interfaces for defining
structs and values. These object types are suitable to use with repositories, as
they can easily build simple objects or complex aggregates and support custom
types for individual attribute values, too.

Here's a simple example how to define a location value:

``` ruby
require 'dry-data'
require 'rom-repository'

rom_container = ROM.container(:sql, 'sqlite::memory') do |rom|
  rom.use :macros

  rom.relation(:locations)
end

class Location < Dry::Data::Value
  attribute :lat, Types::Strict::Float
  attribute :lng, Types::Strict::Float
end

class MyRepository < ROM::Repository::Base
  relations :locations

  def all_locations
    locations.select(:lat, :lng).as(Location).to_a
  end
end

repo = MyRepository.new(rom_container)

repo.all_locations
```
