# Repositories

In ROM, repositories encapsulate access to domain-specific entities. They use
[relations](/guides/basics/relations/) to expose a convenient interface for
composing relations and automatically mapping them to struct objects.

## Installation

Repository is a separate gem:

```
gem install rom-repository
```

## Defining a Repository Class

A repository object gets access to selected relations that are available in the
ROM container object. When you create a repository class you can explicitly define
which relations should be established:

``` ruby
class UserRepository < ROM::Repository::Base
  relations :users

  # your methods go here
end

rom = ROM.finalize.env

user_repo = UserRepository.new(rom)

user_repo.users
```

Once you have access to your relations you can expose access to specific entities
with your custom interface:

``` ruby
class UserRepository < ROM::Repository::Base
  relations :users

  def [](id)
    users.where(id: id).one!
  end
end


rom = ROM.finalize.env

user_repo = UserRepository.new(rom)

user_repo[1]
# #<ROM::Struct[User] id=1 name="Jane">
```

As you can see, the repository automatically maps relation tuples to instances of
`ROM::Struct`.

## ROM Structs

ROM structs are simple data-capsules. They give you access to their values via
attribute `[]` readers and are coercible to a hash. With powerful relation query
DSLs, you can easily compose relations and return data in the expected state.
That's why automatically mapping to small structs is feasible and no custom
mapping is required.

Struct constructor is strict with regards to the attribute hash it receives - if
there are attributes that were not expected you will get an exception.

Here's an example of a struct:

``` ruby
user = user_repo[1]
# #<ROM::Struct[User] id=1 name="Jane">

user.id # 1
user[:id] # 1

user.to_hash # {:id=>1, :name=>"Jane"}
```

ROM repositories generate struct classes for you, so that you don't have to define
them.

<aside class="well">
There's a planned feature with which you'll be able to provide namespaces for your
structs, this will define struct class constants rather than using anonymous classes.
</aside>

## Working With Relations

In ROM, relations represent specific database queries that your application needs
to execute to get its data. It is recommended that you define explicit relation
classes to achieve better encapsulation and simplify composition.

A common pattern is to encapsulate specific relation methods and use those in your
repositories rather than accessing lower-level query DSLs.

``` ruby
class Users < ROM::Relation[:sql]
  def listing
    select(:id, :name, :email, :created_at).order(:name, :id)
  end

  def registered_after(timestamp)
    where { created_at > timestamp }
  end
end

class UserRepository < ROM::Repository::Base
  relations :users

  def new_users(timestamp)
    users.listing.registered_after(timestamp)
  end
end

user_repo.new_users(Time.new(2015))
```

This way, you encapsulate specific queries and domain-specific relation views.
Your application interfaces with simple structs and has no idea how they are
fetched and instantiated.

## Relation Views

Every method that you define in a relation represents a specific relation **view**.
For views that you re-use, to compose more complex relations, you can explicitly
define their structure with the view plugin

``` ruby
class Users < ROM::Relation[:sql]
  view(:listing, [:id, :name, :email, :created_at]) do
    select(:id, :name, :email, :created_at).order(:name, :id)
  end

  def registered_after(timestamp)
    where { created_at > timestamp }
  end
end
```

Thanks to this feature we can be explicit about the data structures our relations
return, this comes with the benefit of auto-mapping and better introspection
capabilities that can be used to build even more advanced features.

<aside class="well">
The view feature will be enhanced with type annotations so that it will be possible
to automatically map database-specific types into domain-specific types.
</aside>

### Base View Plugin

ROM repository provides an SQL relation plugin called base_view, this defines
a base relation view for you which, by default, includes all the column names and
orders by the primary key in descending order:

``` ruby
class Users < ROM::Relation[:sql]
  def filter(conditions)
    base.where(conditions)
  end
end
```

## Composing Relations

Every repository can access multiple relations. Thanks to this you can compose
them however you want and get aggregates back. There's no need
to define associations with complicated configuration logic, you simply define
methods on your repository objects:

``` ruby
class UserRepository < ROM::Repository::Base
  relations :users, :tasks

  def with_tasks(id)
    users.by_id(id).combine_children(many: tasks)
  end
end

user_repo.with_tasks.to_a
# [#<ROM::Struct[User] id=1 name="Jane" tasks=[#<ROM::Struct[Task] id=2 user_id=1 title="Jane Task">]>, #<ROM::Struct[User] id=2 name="Joe" tasks=[#<ROM::Struct[Task] id=1 user_id=2 title="Joe Task">]>]
```

What you see here is an example usage of `auto_combine` plugin.

### Composition Plugins

ROM Repository is built on top of lower-level relation interface of ROM. It ships
with a couple of plugins that are simple syntactic sugar using Relation `combine`
interface under the hood.

The beauty of this approach is that even the most complex scenarios are handled by
the very same composition interface. There's nothing special going on here, we're
simply using relations and their views. When default behavior is not satisfactory,
you can define your own relation view, improve the query yourself and it will work
exactly the same in terms of the internal machanics.

<aside class="well">
Notice that you can compose relations from different databases!
</aside>

#### Auto-Combine Plugin

The 'auto_combine` plugin adds 3 convenient methods for composing relations into
a graph which is automatically mapped to aggregate structs:

- `#combine_parents` automatically joins parents using eager-loading
- `#combine_children` automatically joins children using eager-loading
- `#combine` can accept a simple hash defining what other relations should be joined
  it is used by the `combine_parents` and `combine_children` and is useful when
  your relations don't have conventional foreign-key names

Here are a couple of examples how to combine child relations:

``` ruby
class UserRepository < ROM::Repository::Base
  relations :users, :tasks

  def with_tasks(id)
    users.by_id(id).combine_children(many: tasks)
  end

  def with_recent_tasks(id)
    users.by_id(id).combine_children(many: tasks.recent)
  end

  def with_top_priority_task(id)
    users.by_id(id).combine_children(one: tasks.top_priority)
  end
end
```

Here are a couple of examples how to combine parent relations:

``` ruby
class TaskRepository < ROM::Repository::Base
  relations :users, :tasks

  def with_user(id)
    tasks.by_id(id).combine_parents(one: users)
  end

  def with_owner(id)
    tasks.by_id(id).combine_parents(one: { owner: users })
  end
end
```

You can mix it however you want and combine both child and parent relations:

``` ruby
class TaskRepository < ROM::Repository::Base
  relations :users, :tasks, :tags

  def with_owner_and_tags(id)
    tasks
      .by_id(id)
      .combine_parents(one: { owner: users })
      .combine_children(tags: tags)
  end
end
```

You can override default `combine` logic by simply implementing your own view:

``` ruby
class Tags < ROM::Relation[:sql]
  view(:for_tasks, [:id, :name, :task_id]) do |tasks|
    # do whatever you want
  end
end

class TaskRepository < ROM::Repository::Base
  relations :tasks, :tags

  def with_tags(id)
    # now your own `for_tasks` will be called
    tasks.by_id(id).combine_children(tags: tags)
  end
end
```

#### Auto-Wrap Plugin

ROM allows you to map joined relations to aggregates too. This is done via `wrap`
operation and repository interface gives you a convenience method which does what
you need:

``` ruby
class TagsRepository < ROM::Repository::Base
  relations :tasks, :tags

  def with_task(id)
    tags.by_id(id).wrap_parent(task: tasks)
  end
end
```

The result is exactly the same as if you used `combine_parents` with the exception
of the query logic - in case of wrapping we are using an inner join.

If the default query isn't doing what you want you can override it:

``` ruby
class Tags < ROM::Relation[:sql]
  def for_wrap(join_keys, parent_relation_name)
    # do what you want
  end
end
```
