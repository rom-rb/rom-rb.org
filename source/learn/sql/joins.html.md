---
title: SQL Adapter
chapter: Joins
---

To load associated relations you can simply use `inner_join` or `left_join`:

``` ruby
class Users < ROM::Relation[:sql]
  def with_tasks
    inner_join(:tasks, user_id: :id)
  end

  def with_posts
    left_join(:posts, user_id: :id)
  end
end
```

#### Qualifying and Renaming Attributes

Joining relations introduces a problem of having conflicting attribute names. To
solve this you often need to qualify and rename columns.

To qualify all attributes in a relation:

``` ruby
class Users < ROM::Relation[:sql]
  def with_tasks
    qualified.inner_join(:tasks, user_id: :id)
  end
  # produces "SELECT users.id, users.name ..."
end
```

To rename all attributes in a relation:

``` ruby
class Users < ROM::Relation[:sql]
  def with_tasks
    prefix(:user).qualified.inner_join(:tasks, user_id: :id)
  end
  # produces "SELECT users.id AS user_id, users.name AS user_name ..."
end
```

#### Using Renamed Attributes in GROUP or WHERE Clauses

If attributes need to be qualified and you want to use them in `group` or `where`
you can use special syntax with double-underscore:

``` ruby
class Users < ROM::Relation[:sql]
  def with_tasks
    prefix(:user)
      .qualified
      .inner_join(:tasks, user_id: :id)
      .where(users__name: 'Jane')
  end
  # produces "SELECT ... FROM ... WHERE users.name = 'Jane'"
end
```

#### Mapping Joined Relations (advanced usage)

You can map a result from a join to a single aggregate using mappers:

``` ruby
class Users < ROM::Relation[:sql]
  def with_tasks
    joinable
      .inner_join(:tasks, user_id: :id)
      .select_append(:tasks__title)
  end

  def joinable
    prefix(:user).qualified
  end
end

class UserMapper < ROM::Mapper
  relation :users
  register_as :user_with_tasks

  attribute :id, from: :user_id
  attribute :name, from: :user_name

  group :tasks do
    attribute :title
  end
end

rom.relations[:users].map_with(:user_with_tasks).with_tasks.one
```

This technique is brittle as it requires careful selection of the attributes and
dealing with potential name conflicts; however, *for performance reasons you may
have cases where you would prefer to use joins*.

Here, ROM doesn't block you, and gives you all that's needed to map complex join
results into a simple domain aggregate.

> In typical cases, the built-in auto-mapping in repositories is all you need.
> Even when you need custom queries, it's still much easier to define custom
> relations for composition and use `Repository#combine` API which uses
> eager-loading for associated relation data.
