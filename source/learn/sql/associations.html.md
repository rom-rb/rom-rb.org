---
title: SQL
chapter: Associations
---

Relation schemas in SQL land can be used to define canonical associations. These
definitions play important role in automatic mapping of aggregates in repositories.

#### belongs_to (many-to-one)

The `belongs_to` definition establishes a many-to-one association type.

``` ruby
class Post < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      belongs_to :user
    end
  end
end
```

#### has_many (one-to-many)

The `has_many` definition establishes a one-to-many association type.

``` ruby
class Users < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      has_many :tasks
    end
  end
end
```

#### has_many-through (many-to-many)

The `has_many` definition supports `:through` option which establishes a
many-to-many association type.

``` ruby
class Users < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      has_many :tasks, through: :users_tasks
    end
  end
end

class UsersTasks < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      belongs_to :user
      belongs_to :task
    end
  end
end
```

#### has_one (one-to-one)

The `has_one` definition establishes a one-to-one association type.

``` ruby
class Users < ROM::Relation[:sql]
  schema(infer: true) do
    has_one :account
  end
end
```

#### has_one-through (one-to-one-through)

The `has_one` definition supports `:through` option which establishes a
one-to-one-through association type.

``` ruby
class Users < ROM::Relation[:sql]
  schema(infer: true) do
    has_one :account, through: :users_accounts
  end
end

class UsersAccounts < ROM::Relation[:sql]
  schema(infer: true) do
    belongs_to :account
    belongs_to :user
  end
end
```

#### Aliasing an association

If you want to use a different name for an association, you can use `:as` option.
All association types support this feature.

In example, let's say we have `:posts` belonging to `:users` but we'd like to call
them `:authors`:

``` ruby
class Post < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      belongs_to :user, as: :author
    end
  end
end
```

> An alias is used by repositories, which means that in our example, if you load
> an aggregate with posts and its authors, the attribute name in post structs
> will be called **author**
