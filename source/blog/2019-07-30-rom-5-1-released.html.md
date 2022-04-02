---
title: ROM 5.1 released
date: 2019-07-30
tags: release,announcement
author: Piotr Solnica
---

We're happy to announce the release of the rom suite 5.1.0! This release includes a couple of bug fixes and mostly focuses on improvements in the `ROM::Transformer` API and adds plugin APIs to `ROM::Repository` and `ROM::Changeset`. Let's take a look at these nice additions!

## Improved Transformer API

Currently `ROM` has two different APIs for defining custom mappers. One, called `ROM::Mapper`, is the old API that goes back to the very early days of the project. In version `4.0` a new API was introduced called `ROM::Transformer`, with the intention to eventually replace  `ROM::Mapper` as Transformer API is more straight-forward and powerful than the original one.

In `5.1.0` we've made significant improvements that make using transformer-based mappers even better than before. Here's how it looks like in rom `5.1.0` with its new `map` method:

```ruby
class JSONSerializer < ROM::Transformer
  map do
    nest(:address, %i[city street zipcode])
    deep_stringify_keys
  end
end
```

You can easily check out how it works by simply creating an instance and calling it with some data as input:

```ruby
json_serializer = JSONSerializer.new

json_serializer.(
  [{ name: "Jane", city: "Cracow", street: "Street 1/2", zipcode: "12-345" }]
)
# => [{"name"=>"Jane",
#      "address"=>{"city"=>"Cracow", "street"=>"Street 1/2", "zipcode"=>"12-345"}
#    }]
```

Another big improvement is **support for instance methods as mapping functions**. Sometimes you need to access mapper's state in order to perform some mapping, this is where instance methods come in handy:

```ruby
class JSONSerializer < ROM::Transformer
  map do
    # map zipcode using the corresponding instance method
    map_value(:zipcode, &:normalize_zipcode)
    nest(:address, %i[city street zipcode])
    deep_stringify_keys
  end

  def normalize_zipcode(zipcode)
    # do whatever you need
  end
end
```

Transformers are typically registered within a rom container, this part has been simplified too and you can now do it in one line, which is consistent with other rom components. If we wanted to register our `JSONSerializer` to be a mapper used by the `users` relation, we could simply do this now:

```ruby
class JSONSerializer < ROM::Transformer
  relation :users, as: :json

  map do
    nest(:address, %i[city street zipcode])
    deep_stringify_keys
  end
end
```

Then the transformer will be available under `:json` identifier:

```ruby
# assuming `users` is our relation
users.map_with(:json).to_a
```

## Plugin API for Repository and Changeset

Starting from rom `5.1.0` you can write plugins for repositories and changesets. This is a huge improvement that you should find useful whether you're integrating rom with your library or just want to DRY-up code in an application. Currently there are no built-in plugins for repositories or changesets, but it's very likely we'll be adding some in the near future.

Here's an example of a repository plugin that sets "default scope" for a repository root relation:

```ruby
module DefaultScope
  class ScopedRelation < Module
    attr_reader :name, :view

    def initialize(name, view)
      @name = name
      @view = view
      define_relation_reader
    end

    private

    def define_relation_reader
      relation_view = view

      define_method(name) do
        super().public_send(relation_view)
      end
    end
  end

  def self.apply(repo, view:)
    repo.prepend(ScopedRelation.new(repo.root, view))
  end
end

ROM.plugins do
  register :default_scope, DefaultScope, type: :repository
end
```

Now we can enable our plugin in a root repository:

```ruby
class PostRepo < ROM::Repository[:posts]
  use :default_scope, view: :published
end
```

That's it - the repository will always use posts scoped to its `published` view.

## Release information

This is a backward-compatible release, which means upgrading should not break your code. If you have any issues please [report them](https://github.com/rom-rb/rom/issues/new/choose). Please refer to [5.1.0 CHANGELOG](https://github.com/rom-rb/rom/blob/main/CHANGELOG.md#510-2019-07-30) for more information.