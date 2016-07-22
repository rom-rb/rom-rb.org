---
title: Repositories
chapter: Changesets
---

You already learned how to simply use commands with repositories in the
[Quick Start](/learn/repositories/quick-start) section, but there's so much more
to it! In this section you're going to learn how to use <mark>Changesets</mark>
along with repositories.

## Changesets

Persisting data in a database can be complex. You often need to pre-process the
data before it can be persisted. Whenever additional processing needs to happen
you can use <mark>Changesets</mark> to prepare the data before they can be sent
down to the command.

Changesets can be build using `Repository#changeset` method, here's how you can
work with them:

``` ruby
require 'rom-repository'

rom = ROM.container(:sql, 'sqlite::memory') do |conf|
  conf.default.create_table(:users) do
    primary_key :id
    column :name, String, null: false
    column :email, String, null: false
    column :created_at, DateTime
    column :updated_at, DateTime
  end
end

class UserRepo < ROM::Repository[:users]
  commands :create, update: :by_pk
end

user_repo = UserRepo.new(rom)

user = user_repo.create(name: 'Jane', email: 'jane@doe.org')

changeset = user_repo.changeset(user.id, name: 'Jane Doe')

changeset.diff? # true
changeset.diff # {name=>"Jane Doe"}
```

Changesets are compatible with commands, as they implement `Hash` interface, this
means you can pass them to commands. In order to save a changeset, simply pass it
to `update` command method:

``` ruby
user_repo.update(user.id, changeset)
# => #<ROM::Struct[User] id=1 name="Jane Doe" email="jane@doe.org">
```

Repositories **will not execute an update command** if there's no diff between
the original tuple and the new one, ie:

``` ruby
changeset = user_repo.changeset(user.id, email: 'jane@doe.org')

changeset.diff? # false

# no UPDATE query is executed
user_repo.update(user.id, changeset)
```

## Changeset Mapping

Changeset has an extendible data-pipe mechanism available via `Changeset#map` which
accepts a list of additional mapping steps that will be executed before sending
data to a command. These steps are functions provided by the changeset's `pipe` object.

You have access to a couple of built-in steps:

* `:add_timestamps` - sets `created_at` and `updated_at` timestamps
* `:touch` - sets `updated_at` timestamp

Here's how you can prepare a changeset with additional mapping steps:

``` ruby
changeset = user_repo
  .changeset(name: 'Joe', email: 'joe@doe.org')
  .map(:add_timestamps)

user_repo.create(changeset)
# => #<ROM::Struct[User] id=1 name="Joe" email="joe@doe.org" created_at=2016-07-22 14:45:02 +0200 updated_at=2016-07-22 14:45:02 +0200>
```

> At the moment there's no public API for extending the built-in pipe with additional
> functions, but don't worry, it'll be added soon :)
