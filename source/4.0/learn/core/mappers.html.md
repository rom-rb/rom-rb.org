---
chapter: Core
title: Mappers
---

Mappers are used to process relation data, this may involve merging results from
multiple relations into nested data structures or instantiating custom objects.
Relations generate their mappers automatically for most common use cases, but
mappers are separated from relations, which means you can always define your own
mappers, whenever you have the need.

## Default relation mappers

Relations are configured to map automatically to plain hashes by default. When you're
using relations via repostories, they are configured to map to `ROM::Struct` by default,
and you can define custom struct namespace, if you want your own objects to be instantiated
instead.

Here's how default mapping looks like, assuming you have a users relation available:

``` ruby
class Users < ROM::Relation[:sql]
  schema(infer: true) do
    has_many :tasks
  end
end

users.by_pk(1).one
=> {:id=>1, :name=>"Jane"}

users.by_pk(1).combine(:tasks).one
=> {:id=>1, :name=>"Jane", :tasks=>[{:id=>1, :user_id=>1, :title=>"One"}, {:id=>2, :user_id=>1, :title=>"Two"}]}
```

## Mapping to custom objects via custom struct namespace

Relations use `auto_struct` feature to create `ROM::Struct` subclasses automatically based
on information in schemas. `ROM::Struct` is the default `struct_namespace` when `auto_struct`
is enabled. You can set your own `struct_namespace` where your custom classes are defined, and
in this case mappers will use this namespace to find struct classes corresponding to your
relations.

``` ruby
module Entities
  class User < ROM::Struct
    def full_name
      "#{first_name} #{last_name}"
    end
  end
end

class Users < ROM::Relation[:sql]
  schema(infer: true)
  
  struct_namespace Entities
  auto_struct true
end

user = users.by_pk(1).one
user.full_name
# => "Jane Doe"
```

### How struct classes are determined

Mappers will look for struct classes based on `Relation#name`, but this is not restricted
to canonical names of your relations, as they can be aliased too. For instance, you may
define `:admins` relation, which is restricted to users with `type` set to `"Admin"`. Then
if you have a `Entities::Admin` class, it will be used as the struct class for `:admins`
relation.

``` ruby
module Entities
  class User < ROM::Struct
    def admin?
      false
    end
  end
  
  class Admin < User
    def admin?
      true
    end
  end
end

class Admins < ROM::Relation[:sql]
  dataset { where(type: "Admin") }

  schema(:users, as: :admins, infer: true)
  
  struct_namespace Entities
  auto_struct true
end

admin = admins.by_pk(1).one

admin.admin?
# true
```

> #### Usage with repositories
> It is advised to configure struct_namespace in repositories, as it's the appropriate
> layer where application-specific data structures are coming from.

## Mapping to custom objects explicitly

You can ask a relation to instantiate your own objects via `Relation#map_to` interface.
Your object class must have a constructor which accepts a hash with attributes.

Here's a simple example:

```ruby
class User
  attr_reader :attributes
  
  def initialize(attributes)
    @attributes = attributes
  end
  
  def [](name)
    attributes[name]
  end
end

users.by_pk(1).map_to(User)
# => #<User:0x007fa7eabf1a50 @attributes={:id=>1, :name=>"Jane"}>
```

## Using custom mappers

A mapper can be any object which responds to `#call`, which accepts a relation and
return an array with results back. This means a simple proc will be just fine:

``` ruby
user_name_mapper = -> users { users.pluck(:name) }

user_names = users >> user_name_mapper

user_names.to_a
=> ["Jane", "John"]
```

Typically though, custom mappers will be used in more complex cases, when the underlying database
doesn't provide enough functionality that's needed to get desired data structures. In such cases,
you can define mapper classes and configure mapping there.

``` ruby
class MyMapper < ROM::Transformer
  relation :users
  register_as :my_mapper
  
  map_array do
    # define custom transformations here
  end
end
```

With a custom mapper configured, you can use `Relation#map_with` interface to send relation data
through your mapper:

``` ruby
users.map_with(:my_mapper).to_a
```

`ROM::Transformer` is powered by [transproc](https://github.com/solnic/transproc#transformer).

## Learn more

* [api::rom::Relation](.schema)
* [api::rom::Relation](.auto_struct)
* [api::rom::Relation](.struct_namespace)
* [api::rom::Relation](#map_to)
* [api::rom::Relation](#map_with)
* [api::rom](Transformer)
