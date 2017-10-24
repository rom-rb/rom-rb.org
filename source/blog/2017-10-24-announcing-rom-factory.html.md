---
title: Announcing rom-factory
date: 2017-10-24
tags: release,announcement
author: Piotr Solnica
---

We're happy to announce a new project that we've been working on - rom-factory. The project was originally started by [Jānis Miezītis](https://github.com/janjiss) back in 2016, and then it was moved to rom-rb organization in March 2017. As you can probably guess, rom-factory is a data generator library, similar to FactoryBot (previously known as FactoryGirl) or Fabrication. It's built on top of rom-rb and has a sweet integration with Faker gem.

Let's see how it looks like.

## Factories

In rom-factory you can define as many factories as you want, we **do not store them under one singleton object**. After you got rom container set up, you can easily configure a factory:

``` ruby
MyFactory = ROM::Factory.configured do |c|
  c.rom = your_rom_container
end

AnotherFactory = ROM::Factory.configured do |c|
  c.rom = your_rom_container
end
```

After setting up a factory, you can start defining your builders:

``` ruby
MyFactory.define(:user) do |f|
  f.name "Jane"
  f.email "jane@doe.org"
end
```

You can ask for an in-memory struct, in which case a primary key value will be auto-generated:

``` ruby
MyFactory.structs[:user]
# #<ROM::Struct::User id=1 name="Jane" email="jane@doe.org"
```

...or you can ask for a struct which will be persisted in your database:

``` ruby
MyFactory[:user]
# #<ROM::Struct::User id=1 name="Jane" email="jane@doe.org"
```

## Dynamic values with sequences, re-using other values and faker

Having static values is often not enough, which is why rom-factory has a couple of neat features which allow you to define dynamic values. The first one is sequencing:

``` ruby
MyFactory.define(:user) do |f|
  f.sequence(:email) { |n| "user-#{n}@rom-rb.org" }
end
```

You can also re-use values from other attributes:

``` ruby
MyFactory.define(:user) do |f|
  f.name "Jane"
  f.email { |name| "#{name}@rom-rb.org" }
end
```

We also added support for faker, which makes defining builders more concise:

``` ruby
MyFactory.define(:user) do |f|
  f.name { fake(:name) }
  f.email { fake(:internet, :email) }
  f.age { fake(:number, :between, 10, 100) }
end
```

## Associations

Currently `has_many`, `has_one` and `belongs_to` are supported. Here are a couple examples:

``` ruby
MyFactory.define(:user) do |f|
  f.name { fake(:name) }
  f.email { fake(:internet, :email) }

  # this will use :group builder to create a group for a user
  f.association(:group)
  
  # this will create 2 posts for a user
  f.association(:posts, count: 2)
end
```

## Extending existing builders

You can define a builder by extending another one, for example you may have a user and an admin, which sets `admin` attribute to `true`:

``` ruby
MyFactory.define(:user) do |f|
  f.name { fake(:name) }
  f.email { fake(:internet, :email) }
  f.age { fake(:number, :between, 10, 100) }
  f.admin false
end

MyFactory.define(admin: :user) do |f|
  f.admin true
end
```

## Status & Roadmap

This is still in beta phase, current release is 0.5.0. We're planning to turn this into a pure data generator which doesn't assume any specific persistence backend (currently it uses *and* requires rom-core). On top of this, we want to add support for persistence backends. Once this is done, we'll have 1.0.0 ready.

For now, give it a try and tell us what you think. If you have any questions or problems, reach out on [our discussion forum](http://discourse.rom-rb.org).

Useful links:

* GitHub: [rom-rb/rom-factory](https://github.com/rom-rb/rom-factory)
* API docs: [rubydoc.info/gems/rom-factory](http://www.rubydoc.info/gems/rom-factory/0.5.0)
