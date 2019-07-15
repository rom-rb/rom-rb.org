---
title: Announcing rom-http
date: 2019-04-29
tags: release,announcement,http
author: Piotr Solnica
---

Today we have another exciting release for you - `rom-http 0.8.0`. This is the biggest release of this adapter so far, as it's been integrated fully with the core APIs. This means you can now use `rom-http` to build HTTP client libraries, and leverage powerful auto-mapping capabilities of rom-rb.

This adapter works in the same way as any other `rom-rb` adapter. You configure a gateway, register relations with schemas and voilà - you can talk to remote HTTP APIs now. Let's see how this looks in actual code.

## GitHub API Example

To connect to a remote HTTP API you simply provide the `uri` and which response/request handlers should be used, in this case we will set `:json`:

``` ruby
config = ROM::Configuration.new(:http, uri: "https://api.github.com", handlers: :json)
```

Now we can define a relation class. For the purpose of this example we'll use a relation that will query `/orgs` end-point:

``` ruby
module GitHub
  module Resources
    class Organizations < ROM::Relations[:http]
      schema(:orgs) do
        attribute :id, Types::Integer
        attribute :name, Types::String
        attribute :created_at, Types::JSON::Time
        attribute :updated_at, Types::JSON::Time
      end

      def by_name(name)
        append_path(name)
      end
    end
  end
end

config.register_relation(GitHub::Resources::Organizations)

rom = ROM.container(config)
```

We only defined a sub-set of all the attributes, mappers will reject extra keys for us and give us back simpler data structures. Notice the `by_name` view in this class - it appends organization name to the base path. For example `org/rom-rb` is the path we want to use to find an organization named `rom-rb`.

`Relation#append_path` is just one of the many convenient methods that are available, that will help you in constructing HTTP queries. Refer to [API documentation](https://api.rom-rb.org/rom-http/ROM/HTTP/Dataset.html) for more information.

Let's see this in action now:

``` ruby
orgs = rom.relations[:orgs]

# Plain hashes by default unless you set `auto_struct true` globally
orgs.by_name('rom-rb').one
# {:id=>4589832, :name=>"rom-rb", :created_at=>2013-06-01 22:03:54 UTC, :updated_at=>2019-04-03 14:36:48 UTC}

# Auto-structs on demand
orgs.with(auto_struct: true).by_name('rom-rb').one
# #<ROM::Struct::Org id=4589832 name="rom-rb" created_at=2013-06-01 22:03:54 UTC updated_at=2019-04-03 14:36:48 UTC>
```

Sweet. Data automatically converted to the exact format that we wanted to have, with unspecified keys rejected and attribute values coerced to configured types.

## Release Information

For more information refer to [the CHANGELOG](https://github.com/rom-rb/rom-http/blob/master/CHANGELOG.md#v080-2019-04-29).

Give this adapter a try and tell us what you think!
