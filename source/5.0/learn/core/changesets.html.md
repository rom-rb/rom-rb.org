---
chapter: Core
title: Changesets
---

Changesets are an advanced abstraction for making changes in your database. They
work on top of commands, and provide additional data mapping functionality and 
have support for associating data.

Built-in changesets support all core command types, you can also define custom
changeset classes and connect them to custom commands.


## Working with changesets

You can get a changeset object via `Relation#changeset` interface. A changeset object
wraps input data, and may optionally convert it into a representation that's compatible
with your database schema.

Assuming you have a users relation available:

### `:create` example

``` ruby
users.changeset(:create, name: "Jane").commit
=> {:id=>1, :name=>"Jane"}
```

### `:update` example

``` ruby
users.by_pk(4).changeset(:update, name: "Jane Doe").commit
=> {:id=>4, :name=>"Jane Doe"}
```

> #### Checking diffs
> Update changesets check the difference between the original tuple and new data.
> If there's no diff, an update changeset **will not execute its command**

### `:delete` example

``` ruby
users.by_pk(4).changeset(:delete).commit
=> {:id=>4, :name=>"Jane Doe"}

users.by_pk(4).changeset(:delete).commit
# => nil
```

### Restricting relations for changesets

In the examples above, we used `Relation#by_pk` method, this is a built-in method which
restricts a relation by its primary key; however, you can use any method that's available,
including native adapter query methods.

## Changeset Mapping

Changesets have an extendible data-pipe mechanism available via `Changeset.map`
(for preconfigured mapping) and `Changeset#map` (for on-demand run-time mapping).

Changeset mappings support all transformation functions from [transproc](https://github.com/solnic/transproc) project,
and in addition to that we have:

* `:add_timestamps`–sets `created_at` and `updated_at` timestamps (don't forget to add those fields to the table in case of using `rom-sql`)
* `:touch`–sets `updated_at` timestamp

### Pre-configured mapping

If you want to process data before sending them to be persisted, you can define
a custom Changeset class and specify your own mapping. Let's say we have a nested
hash with `address` key but we store it as a flat structure with address attributes
having `address_*` prefix:

``` ruby
class NewUserChangeset < ROM::Changeset::Create
  map do
    unwrap :address, prefix: true
  end
end
```

Then we can ask users relation for your changeset:

``` ruby
user_data = { name: 'Jane', address: { city: 'NYC', street: 'Street 1' } }

changeset = users.changeset(NewUserChangeset, user_data)

changeset.to_h
# { name: 'Jane', address_city: 'NYC', address_street: 'Street 1' }

changeset.commit
```

### Custom mapping block

If you don't want to use built-in transformations, simply configure a mapping and
pass `tuple` argument to the map block:

``` ruby
class NewUserChangeset < ROM::Changeset::Create
  map do |tuple|
    tuple.merge(created_on: Date.today)
  end
end

user_data = { name: 'Jane' }

changeset = users.changeset(NewUserChangeset, user_data)

changeset.to_h
# { name: 'Jane', created_on: <Date: 2017-01-21 ((2457775j,0s,0n),+0s,2299161j)> }

user_repo.create(changeset)
# => #<ROM::Struct[User] id=1 name="Jane" created_on=2017-01-21>
```

> Custom mapping blocks are executed in the context of your changeset objects,
> which means you have access to changeset's state

### On-demand mapping

There are situations where you would like to perform an additional mapping but adding
a special changeset class would be an overkill. That's why it's possible to apply
additional mappings at run-time without having to use a custom changeset class.
To do this simply use `Changeset#map` method:

``` ruby
changeset = users
  .changeset(:create, name: 'Joe', email: 'joe@doe.org')
  .map(:add_timestamps)

changeset.commit(changeset)
# => #<ROM::Struct[User] id=1 name="Joe" email="joe@doe.org" created_at=2016-07-22 14:45:02 +0200 updated_at=2016-07-22 14:45:02 +0200>
```

### Associating data

Changesets can be associated with each other using `Changeset#associate`
method, which will automatically set foreign keys for you, based on schema associations.

Let's define `:users` relation that has many `:tasks`:

``` ruby
class Users < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      has_many :tasks
    end
  end
end

class Tasks < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      belongs_to :user
    end
  end
end
```

With associations established in the schema, we can easily associate data using
changesets and commit them in a transaction:

``` ruby
task = tasks.transaction do
  user = users.changeset(:create, name: 'Jane').commit

  new_task = tasks.changeset(:create, title: 'Task One').associate(user)

  new_task.commit
end

task
# {:id=>1, :user_id=>1, :title=>"Task One"}
```

> ### Association name
>
> Notice that `associate` method can accept a rom struct and it will try to infer
> association name from it. If this fails because you have an aliased association
> then pass association name explicitly as the second argument, ie: `associate(user, :author)`

## Learn more

* [api::rom](Changeset)
* [api::rom::Changeset](Create)
* [api::rom::Changeset](Update)
* [api::rom::Changeset](Delete)
* [api::rom::Changeset](Associated)

