Wrapping
========

The method [wrap] takes fields from the [relation](file:../relation/index.md)-provided tuple,
and wraps them to either a tuple, or a tuple-based model.

* [base use](#base-use)
* [removing prefixes](#removing-prefixes)
* [renaming attributes](#renaming-attributes)
* [wrapping to model](#wrapping-to-model)
* [nesting wrappers](#nesting-wrappers)
* [wrapping keys](#wrapping-keys)
* [alternatives to wrapping](#alternatives)

[wrap]: http://www.rubydoc.info/gems/rom/ROM/Mapper/AttributeDSL:wrap

Base Use
--------

Suppose there is a predefined relation that returns an array of tuples:

```ruby
users = ROM.env.relations(:users)
users.first
# { id: 1, name: "Jane", contact_email: "jane@example.com", contact_skype: "jane" }
```

With a `wrap` we can take `:contact_email` and `:skype` fields
and wrap them into the `:contact` field:

```ruby
class UserMapper < ROM::Mapper
  register_as :entity
  relation :users

  attribute :id
  attribute :name
  wrap contact: [:contact_email, :contact_skype]
end

users.as(:entity).first
# {
#   id: 1, name: "Jane",
#   contact: { contact_email: "jane@example.com", contact_skype: "jane" }
# }
```

### Alternative Syntax

Just the same result can be obtained by using the block
with attributes defined inside:

```ruby
class UserMapper
  register_as :entity
  relation :users

  attribute :id
  attribute :name

  wrap :contact do
    attribute :contact_email
    attribute :contact_skype
  end
end

users.as(:entity).first
# {
#   id: 1, name: "Jane",
#   contact: { contact_email: "jane@example.com", contact_skype: "jane" }
# }
```

Removing Prefixes
-----------------

Use `:prefix` and `:prefix_separator` options to remove prefixes from wrapped attributes.
The `attribute` method arguments should have no prefixes.

```ruby
class UserMapper
  register_as :entity
  relation :users

  attribute :id
  attribute :name

  wrap :contacts, prefix: 'contact', prefix_separator: '_' do
    attribute :email
    attribute :skype
  end
end

users.as(:entity).first
# {
#   id: 1, name: "Jane",
#   contacts: { email: "jane@example.com", skype: "jane" }
# }
```

### Alternative syntax

Alternatively, use the [prefix](prefix.md) method inside the block.

The method is called without attributes and cannot customize either prefix, or its separator.
It uses the prefix from the name of the `wrap`, separated by the underscore `"_"`.

```ruby
class UserMapper
  register_as :entity
  relation :users

  attribute :id
  attribute :name

  wrap :contact do
    prefix
    attribute :email
    attribute :skype
  end
end

users.as(:entity).first
# {
#   id: 1, name: "Jane",
#   contact: { email: "jane@example.com", skype: "jane" }
# }
```

Renaming Attributes
-------------------

To rename wrapped attributes separately use the triple underscore `"___"` in their names:

```ruby
class UserMapper
  register_as :entity
  relation :users

  attribute :id
  attribute :name

  wrap :contact, [:contact_email___to_write, :contact_skype___to_chat]
end

users.as(:entity).first
# {
#   id: 1, name: "Jane",
#   contact: { to_write: "jane@example.com", to_chat: "jane" }
# }
```

### Alternative Syntax

Inside the block use the `:from` option of the [attribute](attribute.md) method:

```ruby
class UserMapper
  register_as :entity
  relation :users

  attribute :id
  attribute :name

  wrap :contact do
    attribute :to_write, from: :contact_email
    attribute :to_chat,  from: :contact_skype
  end
end
```

Wrapping to Model
-----------------

Define the [model](model.md) to convert the tuple into:

```ruby
require "ostruct"

class UserMapper
  register_as :entity
  relation :users

  attribute :id
  attribute :name

  wrap :contact do
    model     OpenStruct
    attribute :contact_email
    attribute :contact_skype
  end
end

users.as(:entity).first
# {
#   id: 1, name: "Jane",
#   contact: <OpenStruct contact_email="jane@example.com", contact_skype="jane">
# }
```

Nesting Wrappers
----------------

Wrappers can be nested:

```ruby
require "ostruct"

class UserMapper
  register_as :entity
  relation :users

  attribute :id
  attribute :name

  wrap :contacts do
    model OpenStruct
    attribute :email, from: :contact_email

    wrap :chats do
      attribute :skype, from: :contact_skype
    end
  end
end

users.as(:entity).first
# {
#   id: 1, name: "Jane",
#   contacts: <OpenStruct email="jane@example.com", chats={:skype=>"jane"}>
# }
```

Wrapping Keys
-------------

The method `wrap` can be applied to keys, that included by the [reject_keys: false](reject_keys.md) setting as well.

```ruby
class UserMapper
  register_as :entity
  relation :users
  reject_keys false
  wrap :contacts, [:email, :skype], prefix: 'contact'
end

users.as(:entity).first
# {
#   id: 1, name: "Jane",
#   contacts: { email: "jane@example.com", skype: "jane" }
# }
```

As shown in previous sections, when a `reject_keys` is set to default (`true`),
wrapping defaults attributes by itself:

```ruby
class UserMapper
  register_as :entity
  relation :users
  wrap :contacts, [:email, :skype], prefix: 'contact'
end

users.as(:entity).first
# { contacts: { email: "jane@example.com", skype: "jane" } }
```

Alternatives
------------

Consider using [combine](combine.md)
to join relations as *one-to-one* or *many-to-one*
and combine the results to corresponding models.

Consider using [group](group.md)
to join relations as *one-to-many* or *many-to-many*
and group the results to array of submodels.
