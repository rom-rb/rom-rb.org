---
title: ROM 4.0.0 released
date: 2017-10-18
tags: release,announcement
author: Piotr Solnica
---

After over six months of work, we're pleased to announce the release of rom-rb 4.0.0! This is a major release which brings many improvements and new features. One of the biggest priorities of this release was to solidify and improve automatic mapping capabilities, by extending core API with features that were previously implemented only in rom-repository. This means that the most advanced features, such as automatic mappers or inferring struct objects, are now part of core API, and it makes using rom-rb much simpler. Apart from this, we also added Association API to the core, which enables associations for all adapters, and you can define associations between different databases.

Here are some of the highlights of 4.0.0 release.

## Automatic mapping

Starting with 4.0.0, rom-rb can infer mappers on-the-fly for all relations. It can generate mappers for "flat" relations, as well as combined or wrapped relations. You don't have to use any structs (aka models) to use this feature, it works with plain hashes too.

Let's say we have users and tasks relations:

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

Now we can load data using these relations easily, including preloaded association data:

``` ruby
> users.first
=> {:id=>1, :name=>"Jane"}

> users.combine(:tasks).first
=> {:id=>1, :name=>"Jane", :tasks=>[{:id=>1, :user_id=>1, :title=>"Jane's task"}]}

> tasks.wrap(:user).first
=> {:id=>1, :user_id=>1, :title=>"Jane's task", :user=>{:id=>1, :name=>"Jane"}}
```

## Auto-struct mapping

Relations can now automatically infer struct objects based on their schema information. This feature can be enabled via `auto_struct` setting and **it is enabled by default, when you use relations through repositories**. Let's tweak previous example to use this feature:

``` ruby
class Users < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      has_many :tasks
    end
  end

  auto_struct true
end

class Tasks < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      belongs_to :user
    end
  end

  auto_struct true
end
```

Now we will get convenient struct objects back:

``` ruby
> users.first
=> #<ROM::Struct::User id=1 name="Jane">

> users.combine(:tasks).first
=> #<ROM::Struct::User id=1 name="Jane" tasks=[#<ROM::Struct::Task id=1 user_id=1 title="Jane's task">]>

> tasks.wrap(:user).first
=> #<ROM::Struct::Task id=1 user_id=1 title="Jane's task" user=#<ROM::Struct::User id=1 name="Jane">>
```

## Support for custom struct classes

This is probably the biggest enhancement, you can now configure your own `struct_namespace` where your own struct classes are defined, and there's no need to define attributes. This can be called "Active Record mode" (in a good way!). Resulting struct objects are still decoupled from the database, their structure is based on relation data, which can be projected anyhow you want. This means that we have dynamic struct objects, but without 1:1 mapping between your database schema and their attributes.

Let's say you decide to put your own struct classes under `Entities` module. This module can be configured as the `struct_namespace`, and rom mappers will automatically find classes, matching relation names. Here's an example:

``` ruby
module Entities
  class User < ROM::Struct
    def task_titles
      tasks.map(&:title)
    end
  end
end

class Users < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      has_many :tasks
    end
  end

  auto_struct true
  struct_namespace Entities
end

class Tasks < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      belongs_to :user
    end
  end

  auto_struct true
  struct_namespace Entities
end
```

Now we will get instances of your own struct class:

``` ruby
> jane = users.combine(:tasks).first
> jane.task_titles
=> ["Jane's task"]
```

You can learn more about this feature [in our updated docs](/4.0/learn/core/structs/)

## Standalone changesets

Changesets are now provided by a separate `rom-changeset` gem and they no longer need repositories. Relations are extended by `:changeset` plugin, which adds `Relation#changeset` method. This makes using changesets more straightforward, here's an example:

``` ruby
users.changeset(:create, name: "John").commit
# {:id=>2, :name=>"John"}

user_changeset = users.by_pk(2).changeset(:update, name: "John Doe")

user_changeset.diff?
# => true

user_changeset.diff
# => {:name=>"John Doe"}

user_changeset.commit
# {:id=>2, :name=>"John Doe"}
```

See [Changeset documentation for more information](learn/core/changesets/).

## ...and more

There are dozens of other improvements and new features, to quickly summarize few more:

* Experimental **auto-migration feature** known from DataMapper project - you will hear more about this soon!
* You no longer need to define `relations` in repository classes
* You can define custom association views with non-standard combine/join keys
* Configuration uses an event bus now, which you can use to hook into setup process and enable additional features. Our plugin system uses it already.
* New APIs have been added to rom-sql, including `SQL::Relation#exists`, `SQL::Relation#each_batch`, `SQL::Relation#import` and `SQL::Relation#explain` (for PG)
* SQL conditions can be negated by using idiomatic `!` operator, ie `users.where { !admin.is(true) }`

## Release information and upgrading

This is a major release with breaking changes. Please refer to [the upgrade guide](https://github.com/rom-rb/rom/wiki/4.0-Upgrade-Guide) for more information. As part of 4.0.0, following gems have been released:

* `rom-core 4.0.0` [CHANGELOG](https://github.com/rom-rb/rom/blob/main/core/CHANGELOG.md)
* `rom-mapper 1.0.0` [CHANGELOG](https://github.com/rom-rb/rom/blob/main/mapper/CHANGELOG.md)
* `rom-repository 1.0.0` [CHANGELOG](https://github.com/rom-rb/rom/blob/main/repository/CHANGELOG.md)
* `rom-changeset 1.0.0` [CHANGELOG](https://github.com/rom-rb/rom/blob/main/changeset/CHANGELOG.md)
* `rom 4.0.0` [CHANGELOG](https://github.com/rom-rb/rom/blob/main/CHANGELOG.md) - this is now a meta-gem which depends on all core components
* `rom-sql 2.0.0` [CHANGELOG](https://github.com/rom-rb/rom-sql/blob/main/CHANGELOG.md)

If you're having problems with the upgrade, please seek for help on [discussion forum](https://discourse.rom-rb.org).

## Thank you :)

Thank you to all our contributors and supporters. Special thanks go to [Nikita Shilnikov](https://github.com/flash-gordon) for his amazing work on making rom-sql better, implementing auto-migrations feature and helping with development of core APIs and addressing issues!

This has been the biggest effort so far, and it's probably the most important release we've had. We'll continue working on bug-fix and minor upgrades soon (there are already PRs opened with new features!), so stay tuned.

Check out rom-rb 4.0.0 and tell us what you think!
