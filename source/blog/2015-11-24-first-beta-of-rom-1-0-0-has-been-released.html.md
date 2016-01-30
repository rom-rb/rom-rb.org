---
title: First Beta of ROM 1.0.0 Has Been Released
date: 2015-11-24
tags: announcement
author: Piotr Solnica
---
Exactly a year ago ROM 0.3.0 was released after [the reboot of the project was announced](http://solnic.eu/2014/10/23/ruby-object-mapper-reboot.html), it was a complete rewrite that introduced the new and simplified adapter interface. Since then we've come a long way, the community has been growing, rom-rb organization on Github has now 28 projects including 16 adapters.

The core API, which also includes adapter interface, is stabilizing. This means we are coming very close to releasing the final version of rom 1.0.0 and today I'm very happy to announce that its first beta1 was released. Please notice this is the release of the core rom gem - adapters and other extensions remain unstable (in the sem-ver sense).

To ease testing we also released beta versions of minor upgrades of other rom gems so that you can install them from rubygems rather than relying on github sources. Overall the release includes following updates:

- [rom](https://rubygems.org/gems/rom) 1.0.0.beta1 [CHANGELOG](https://github.com/rom-rb/rom/blob/master/CHANGELOG.md#v100-to-be-released)
- [rom-support](https://rubygems.org/gems/rom-support) 1.0.0.beta1 [CHANGELOG](https://github.com/rom-rb/rom-support/blob/master/CHANGELOG.md#v100-to-be-released)
- [rom-mapper](https://rubygems.org/gems/rom-mapper) 0.3.0.beta1 [CHANGELOG](https://github.com/rom-rb/rom-mapper/blob/master/CHANGELOG.md#v030-to-be-released)
- [rom-repository](https://rubygems.org/gems/rom-repository) 0.2.0.beta1 [CHANGELOG](https://github.com/rom-rb/rom-repository/blob/master/CHANGELOG.md#v020-to-be-released)
- [rom-sql](https://rubygems.org/gems/rom-sql) 0.7.0.beta1 [CHANGELOG](https://github.com/rom-rb/rom-sql/blob/master/CHANGELOG.md#v070-to-be-released)
- [rom-rails](https://rubygems.org/gems/rom-rails) 0.6.0.beta1 [CHANGELOG](https://github.com/rom-rb/rom-rails/blob/master/CHANGELOG.md#v060-to-be-released)
- [rom-model](https://rubygems.org/gems/rom-model) 0.2.0.beta1 [CHANGELOG](https://github.com/rom-rb/rom-model/blob/master/CHANGELOG.md#020-to-be-released)

## Changes In Setup API

Setting up ROM has been refactored and specific responsibilites have been broken down into smaller, and explicit, objects. Unfortunately it is a breaking change as `ROM.setup` method is gone. If you're using ROM with rails, things should continue to work, but if you have a custom rom setup additional actions are required.

This was an important change that resulted in a cleaner API, removed complex logic that used to rely on `inheritance` hooks to automatically register components and reduced the amount of global state that ROM relies on.

We kept convenience in mind though and introduced a feature that uses dir/file structure to infer components and register them automatically but without the complexity of relying on `inheritance` hooks.

Here's an example of a step-by-step setup with explicit registration:

``` ruby
# instead of ROM.setup:
config = ROM::Configuration.new(:sql, 'postgres://localhost/rom')

class Users < ROM::Relation[:sql]
end

config.register_relation(Users)

# creates rom container with registered components
container = ROM.container(config)
```

Here's an example of a setup that infers components from dir/file names:

``` ruby
config = ROM::Configuration.new(:sql, 'postgres://localhost/rom')

# configure auto-registration by providing root path to your components
# namespacing is turned off
config.auto_registration("/path/to/components", namespace: false)

# assuming there's `/path/to/components/relations/users.rb`
# which defines `Users` relation class it will be automatically registered

# creates rom container with registered components
container = ROM.container(config)
```

You can also use auto-registration with namespaces, which is turned on by default:

``` ruby
config = ROM::Configuration.new(:sql, 'postgres://localhost/rom')

# configure auto-registration by providing root path to your components
# namespacing is turned on by default
config.auto_registration("/path/to/components")

# assuming there's `/path/to/components/relations/users.rb`
# which defines `Relations::Users` class it will be automatically registered

# creates rom container with registered components
container = ROM.container(config)
```

For a quick-start you can use an in-line style setup DSL:

``` ruby
rom = ROM.container(:sql, 'postgres://localhost/rom') do |config|
  config.use(:macros) # enable in-line component registration

  config.relation(:users) do
    def by_id(id)
      where(id: id)
    end
  end
end

rom.relation(:users) # returns registered users relation object
```

## Command API Improvements

Probably the most noticable improvement/feature is the addition of the command graph DSL. The command graph was introduced in 0.9.0 and it allowed you to compose a single command that will be able to persist data coming in a nested structure, similar to `nested_attributes_for` in ActiveRecord, but more flexible.

This release introduces support for `update` and `delete` commands in the graph as well as a new DSL for graph definitions. Here's an example:

``` ruby
# assuming `rom` is your rom container and you have `create` commands
# for :users and :books relations
command = rom.command # returns command builder

# define a command that will persist user data with its book data
create_command = command.create(user: :users) do |user|
  user.create(:books)
end

# call it with a nested input
create_command.call(
  user: {
    name: "Jane",
    books: [{ title: "Book 1" }, { title: "Book 2" }]
  }
)
```

It also supports `update` (`delete` works in the same way):

``` ruby
# assuming `rom` is your rom container and you have `update` commands
# for :users and :books relations
command = rom.command # returns command builder

# define a command that will restrict user by its id and update it
user_update = command.restrict(:users) { |users, user| users.by_id(user[:id]) }

update_command = command.update(user: user_update) do |user|
  # define an inner update command for books
  books_update = user.restrict(:books) do |books, user, book|
    books.by_user(user).by_id(book[:id])
  end

  user.update(books: books_update)
end

# call it with a nested input
update_command.call(
  user: {
    id: 1,
    name: "Jane Doe",
    books: [{ id: 1, title: "Book 1" }, { id: 2, title: "Book 2" }]
  }
)
```

As a bonus, you are free to use all types of commands in the same graph and have complete freedom in defining how specific relations must be restricted for a given command.

### New Command Result API

Starting from 1.0.0 you can check whether a command result was successful or not:

``` ruby
create_command = command.create(user: :users) do |user|
  user.create(:books)
end

result = create_command.call(
  user: {
    name: "Jane",
    books: [{ title: "Book 1" }, { title: "Book 2" }]
  }
)

result.success? # true if everything went fine, false otherwise
result.failure? # true if it failed, false otherwise
```

## Relation API Extensions

Early version of rom-repository introduced a couple of plugins that now have become part of the core rom gem. They are opt-in and the adapter developers must decide whether or not it makes sense to enable them for adapter relations.

### View

Relation `view` plugin is a DSL for defining relation views with an explicit header definition. It is typically useful for reusable relation projections that you can easily compose together in repositories.

Here's a simple example:

``` ruby
class Users < ROM::Relation[:sql]
  view(:listing, [:id, :name, :email]) do |*order_args|
    select(:id, :name, :email).order(*order_args)
  end
end

rom.relation(:users).listing(:name, :id)
```

This plugin plays major role in relation composition as it defines the header up-front, which allows repositories to generate mappers automatically, which is very convenient. It is also a nice way of specifying re-usable relation projections which some times may indicate where using an actual database view (assuming your db supports it) could simplify your queries.

### Key Inference

This simple plugin provides default value for a foreign-key in a relation. It is used for generating relation views used for composition in the repositories.

You can use it too:

``` ruby
rom.relation(:users).foreign_key # => `:user_id`
```

### Defining Default Datasets

It is now possible to not only specify the name of a relation dataset, but also configure it using a block, when you do that your relation will be initialized with whatever that blocks returns, it is executed in the context of the dataset object:

``` ruby
class Users < ROM::Relation[:sql]
  dataset(:people) do
    select(:id, :name).order(:id)
  end
end
```

### Mapper Extension

There's one new feature in the mapper DSL where you can map values from multiple attributes into a new attribute:

``` ruby
class MyMapper < ROM::Mapper
  attribute :address, from: [:city, :street, :zipcode] do |city, street, zipcode|
    "#{city}, #{street}, #{zipcode}"
  end
end
```

## Release Plan

Please try out the beta releases and provide feedback. Once we are sure that it works for everybody we'll be able to push the first RC and hopefully follow-up with the final 1.0.0 release shortly after the RC. Other gems that are now released as betas will be bumped to final versions and depend on rom 1.0.0 final.

The final release also means a major update of [rom-rb.org](http://rom-rb.org) along with a new set of documentation, guides and tutorials. This is still a work in progress and needs help, please [get in touch](https://gitter.im/rom-rb/chat) if you're interested in helping out.

Once rom 1.0.0 is out there will be major focus on rom-sql and rom-repository. There's a plan to [improve query DSL](https://github.com/rom-rb/rom-sql/issues/48) in rom-sql and provide full CRUD interface for repositories that should be handy for simple applications.

If you see any issues, please report them in the individual issue trackers on Github or main [rom](https://github.com/rom-rb/rom/issues) if you are not sure which gem it relates to.
