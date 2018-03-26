---
chapter: Repositories
title: Changesets
---

You already learned how to simply use commands with repositories in the
[Quick Start](/%{version}/learn/repositories/quick-start) section, but there's so much more
to it! In this section you're going to learn how to use <mark>Changesets</mark>
along with repositories.

Persisting data in a database can be complex. You often need to pre-process the
data before it can be persisted. Whenever additional processing needs to happen
you can use <mark>Changesets</mark> to prepare the data before they can be sent
down to the command.

Changesets can be build using `Repository#changeset` method, here's how you can
work with them:

``` ruby
require 'rom-repository'

rom = ROM.container(:sql, 'sqlite::memory') do |config|
  config.default.create_table(:users) do
    primary_key :id
    column :name, String, null: false
    column :email, String, null: false
  end
end

class UserRepo < ROM::Repository[:users]
  commands :create, update: :by_pk
end

user_repo = UserRepo.new(rom)

user = user_repo.create(name: 'Jane', email: 'jane@doe.org')

changeset = user_repo.changeset(user.id, name: 'Jane Doe')

changeset.diff? # true
changeset.diff # {:name=>"Jane Doe"}
```

Changesets are compatible with commands, as they implement `Hash` interface, this
means you can pass them to commands. In order to save a changeset, simply pass it
to `update` command method:

``` ruby
user_repo.update(user.id, changeset)
# => #<ROM::Struct[User] id=1 name="Jane Doe" email="jane@doe.org">
```

Repositories **will not execute an update command** if there's no diff between
the original tuple and the new one, i.e.:

``` ruby
changeset = user_repo.changeset(user.id, email: 'jane@doe.org')

changeset.diff? # false

# no UPDATE query is executed
user_repo.update(user.id, changeset)
```

## Changeset Mapping

Changeset has an extendible data-pipe mechanism available via `Changeset.map`
(for preconfigured mapping) and `Changeset#map` (for on-demand run-time mapping).

Changeset mappings support all transformation functions from [transproc](https://github.com/solnic/transproc) project,
and in addition to that we have:

* `:add_timestamps`–sets `created_at` and `updated_at` timestamps (don't forget to add those fields to the table in case of using `rom-sql`)
* `:touch`–sets `updated_at` timestamp

You can override the timestamps by simply setting them in the input data.

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

Then we can ask the user repo for our changeset:

``` ruby
user_data = { name: 'Jane', address: { city: 'NYC', street: 'Street 1' } }

changeset = user_repo.changeset(NewUserChangeset).data(user_data)

changeset.to_h
# { name: 'Jane', address_city: 'NYC', address_street: 'Street 1' }

user_repo.create(changeset)
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

changeset = user_repo.changeset(NewUserChangeset).data(user_data)

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
changeset = user_repo
  .changeset(name: 'Joe', email: 'joe@doe.org')
  .map(:add_timestamps)

user_repo.create(changeset)
# => #<ROM::Struct[User] id=1 name="Joe" email="joe@doe.org" created_at=2016-07-22 14:45:02 +0200 updated_at=2016-07-22 14:45:02 +0200>
```

### Committing changesets

Changesets can be committed without the need to use repository command methods. The difference is that by committing a changeset you get back
raw data returned from your database:

``` ruby
new_user = repo.changeset(name: 'Jane')
=> #<ROM::Changeset::Create relation=ROM::Relation::Name(users) data={:name=>"Jane"}>

repo.create(new_user)
=> #<ROM::Struct[User] id=3 name="Jane">

new_user.commit
=> {:id=>4, :name=>"Jane"}
```

### Learn more

Check out API docs:

* [api::rom-repository](Changeset)
* [api::rom-repository::Changeset](Create)
* [api::rom-repository::Changeset](Update)
* [api::rom-repository::Changeset](Delete)
* [api::rom-repository::Changeset](Associated)

### Next

Now you can learn how to [define custom changeset classes](/%{version}/learn/repositories/custom-changesets).
