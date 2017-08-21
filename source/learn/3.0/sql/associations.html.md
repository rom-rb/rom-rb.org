---
chapter: SQL
title: Associations
---

Relation schemas in SQL land can be used to define canonical associations. These
definitions play important role in automatic mapping of aggregates in repositories.

## belongs_to (many-to-one)

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

> #### Naming convention
> This method is a shortcut for `belongs_to :users, as: :user`

## has_many (one-to-many)

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

## has_many-through (many-to-many)

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

## has_one (one-to-one)

The `has_one` definition establishes a one-to-one association type.

``` ruby
class Users < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      has_one :account
    end
  end
end
```

> #### Naming convention
> This method is a shortcut for `has_one :accounts, as: :account`

## has_one-through (one-to-one-through)

The `has_one` definition supports `:through` option which establishes a
one-to-one-through association type.

``` ruby
class Users < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      has_one :account, through: :users_accounts
    end
  end
end

class UsersAccounts < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      belongs_to :account
      belongs_to :user
    end
  end
end
```

## Aliasing an association

If you want to use a different name for an association, you can use `:as` option.
All association types support this feature.

For example, we have `:posts` belonging to `:users` but we'd like to call
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

> The alias is used by repositories, which means that in our example, if you load
> an aggregate with posts and its authors, the attribute name in post structs
> will be called **author**

## Extending associations with custom views

You can use `:view` option and specify which relation view should be used to extend
default association relation. Let's say you have users with many accounts through
users_accounts and you want to add attributes from the join relation to accounts:

``` ruby
class Users < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      has_many :accounts, through: :users_accounts, view: :ordered
    end
  end
end

class Accounts < ROM::Relation[:sql]
  schema(infer: true)

  view(:ordered) do
    schema do
      append(users_accounts[:position])
    end

    relation do
      order(:position)
    end
  end
end
```

This way when you load users with their accounts, they will include `:position`
attribute from the join table and will be ordered by that attribute.

## Using associations to manually preload relations

You can reuse queries that associations use in your own methods too via `assoc`
shortcut method:

``` ruby
class Users < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      has_many :tasks
    end
  end

  def admin_tasks
    assoc(:tasks).where(admin: true)
  end
end
```

## Setting a custom foreign-key

By default, foreign keys found in schemas are used, but you can provide custom names too via
`:foreign_key` option:

``` ruby
class Flights < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      belongs_to :destinations, as: :from, foreign_key: :from_id
      belongs_to :destinations, as: :to, foreign_key: :to_id
    end
  end
end
```

## Using a relation named differently from the table

It's a common case for legacy databases to have tables named differently from relations. Your legacy table name must be the first argument and the corresponding relation name must go with `:relation` option:

``` ruby
class Users < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      has_many :todos, as: :tasks, relation: :tasks
    end
  end
end
```

> All association types support this option

## Learn more

Check out API documentation:

* [api::rom-sql::SQL/Schema](AssociationsDSL)
* [api::rom-sql::SQL/Association](OneToMany)
* [api::rom-sql::SQL/Association](OneToOne)
* [api::rom-sql::SQL/Association](ManyToOne)
* [api::rom-sql::SQL/Association](ManyToMany)
