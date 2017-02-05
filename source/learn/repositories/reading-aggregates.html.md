---
chapter: Repositories
title: Reading Aggregates
---

Repositories have a powerful API for composing data into nested structures, which
we call **aggregates**, where the root is constructed from the data provided by
the root relation, and additional relations provide data for child nodes.

This document uses `rom-sql` which provides support for defining canonical database
associations in relation schemas, which are used to simplify reading aggregates.
If an adapter doesn't support association in schemas, you can still load aggregates
using [`Repository#combine`](http://www.rubydoc.info/gems/rom-repository/ROM/Repository/RelationProxy/Combine) interface,
which is more advanced and flexible.

## Relation Schema

First, we want to define our canonical associations. We call them canonical since
they are defined by your database schema. It's common to diverge from canonical
associations and compose data in different ways, depending on your application needs;
however, in the early days of every project, using canonical associations is all
you need, so let's start with that!

We're going to define `:users` that have many `:tasks`. To keep things simpler
let's define relations using [block-style setup](/learn/getting-started/block-style-setup):

``` ruby
require 'rom'

rom = ROM.container(:sql, 'sqlite::memory') do |conf|
  conf.default.create_table(:users) do
    primary_key :id
    column :name, String, null: false
    column :email, String, null: false
  end

  conf.default.create_table(:tasks) do
    primary_key :id
    foreign_key :user_id, :users
    column :title, String, null: false
  end

  conf.relation(:users) do
    schema(infer: true) do
      associations do
        has_many :tasks
      end
    end
  end

  conf.relation(:tasks) do
    schema(infer: true) do
      associations do
        belongs_to :user
      end
    end
  end
end
```

With associations defined in the relation schemas we established common queries
that will be automatically used for composing relations into aggregates. Let's
see how we can leverage that in repositories.

## Repository Aggregates

Let's say we'd like to expose an aggregate where a user is loaded with its tasks.
We need to define a root repository with `:users` set up as the root and provide
access to `:tasks` relation:

``` ruby
class UserRepo < ROM::Repository[:users]
  # we configure this explicitly so we can see that this repo will work with tasks relation too
  relations :tasks
end
```

Now loading an aggregate is as simple as this:

``` ruby
user_repo = UserRepo.new(rom)

user_repo.aggregate(:tasks).one
# => #<ROM::Struct[User] id=1 name="jane" email="jane@doe.org" tasks=[#<ROM::Struct[Task] id=1 user_id=1 title="Jane Task">]>
```

We can do the other way around, starting with `:tasks` relation as the root, which
means we're going to load a task with its user:

``` ruby
class TaskRepo < ROM::Repository[:tasks]
  relations :users
end

task_repo = TaskRepo.new(rom)

task_repo.aggregate(:user).one
# => #<ROM::Struct[Task] id=1 user_id=1 title="Jane Task" user=#<ROM::Struct[User] id=1 name="jane" email="jane@doe.org" task_id=1>>
```

Notice that in this case `User` struct is loaded as a child object where `Task`
is a parent, thus `User` has `task_id` assigned, which is **a virtual foreign key**
that doesn't really exist in our schema.

### Loading aggregates using wrapping

An alternative, and faster, way of loading **parent objects** is to use `wrap_parent` method:

``` ruby
class TaskRepo < ROM::Repository[:tasks]
  def by_id_with_user(id)
    tasks.by_pk(id).wrap_parent(user: task_repo.users).one
  end
end

task_repo.by_id_with_user(id)
# => #<ROM::Struct[Task] id=1 user_id=1 title="Jane Task" user=#<ROM::Struct[User] id=1 name="jane" email="jane@doe.org">>
```

Notice that unlike with `aggregate` method, the parent object does not include **a virtual foreign key**.

> #### Performance and availability
> `wrap_parent` is **only available in rom-sql**, which uses a join instead of eager-loading
> and **it's significantly faster** than using `aggregate`. Other adapters can implement this
> interface too, assuming it makes sense in case of a given data source.

## Learn more

Loading aggregates with repositories can be achieved in many different ways, for
detailed information about invidual methods please refer to the API documentation:

* [api::rom-repository::Repository/Root](#aggregate)
* [api::rom-repository::Repository/RelationProxy](#combine_children)
* [api::rom-repository::Repository/RelationProxy](#combine_parents)
* [api::rom-repository::Repository/RelationProxy](#combine)
* [api::rom-repository::Repository/RelationProxy](#wrap_parent)
