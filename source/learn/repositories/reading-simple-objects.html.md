---
chapter: Repositories
title: Reading Simple Objects
---

It's best to create multiple Repository classes that each focus on a segment of
the data. One rough guideline is to make a repository for each concept within
your app:

```ruby
# Assuming a database with tables 'users' and 'projects'
rom = ROM.container(:sql, 'sqlite::memory')

# Perhaps one Repo to handle users
class UserRepo < ROM::Repository[:users]
end

# Another repository could handle the projects
class ProjectRepo < ROM::Repository[:projects]
end

user_repo = UserRepo.new(rom)
project_repo = ProjectRepo.new(rom)
```

## Repository Interface

While defining a repository, you will also define its interface for
domain-specific queries. These are called **selector methods**.

They use the querying methods provided by the relations to accomplish their task.
For example, the `rom-sql` adapter provides methods like `Relation#where`.

```ruby
class UserRepo < ROM::Repository[:users]
  # find all users with the given attributes
  def query(conditions)
    users.where(conditions)
  end

  # collect a list of all user ids
  def ids
    users.pluck(:id)
  end
end
```

Read your adapter's documentation to see the full listing of its Relation
methods.

> These are just simple reads. See the [Associations](/learn/associations)
> section to see how to construct multi-relation selector methods using joins.

## Single Results vs Many Results

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

``` ruby
require 'rom-repository'

rom = ROM.container(:sql, 'sqlite::memory') do |conf|
  conf.default.connection.create_table(:users) do
    primary_key :id
    column :name, String, null: false
    column :email, String, null: false
  end
end

class UserRepo < ROM::Repository[:users]
  def query(conditions)
    users.where(conditions).to_a
  end

  def by_id(id)
    users.fetch(id)
  end

  # ... etc
end

user_repo = UserRepo.new(rom)
```

> Notice that `users.where` and `users.fetch` are SQL-specific interfaces that
> should not leak into your application domain layer, that's why we hide them
> behind our own repository interface.

And then in our app we can use the selector methods:

```ruby
# assuming that there is already data present

user_repo.query(first_name: 'Malcolm', last_name: 'Reynolds')
#=> [ROM::Struct[User] , ROM::Struct[User], ...]

user_repo.by_id(1)
#=> ROM::Struct[User]
```

## Mapping To Custom Objects

Repositories can map relations to your custom objects. As a general best-practice
every public repository method should return materialized, domain objects.

> You can use any object type where constructor accepts a hash with attributes.

Let's tweak our `UserRepo#query` method to return our own user models:

``` ruby
class User
  attr_reader :id, :name, :email

  def initialize(attributes)
    @id, @name, @email = attributes.values_at(:id, :name, :email)
  end
end

class UserRepo < ROM::Repository[:users]
  def query(conditions)
    users.where(conditions).as(User)
  end
end
```

## Next

Now we can read simple structs. Next, learn how to [read complex, aggregate data](/learn/repositories/reading-aggregates).
