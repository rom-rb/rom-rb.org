Wrapping Attributes
===================

With the method [wrap] you can take some attributes from a tuple and wrap them to either a nested tuple, or a model.

[wrap]: http://www.rubydoc.info/gems/rom/ROM/Mapper/AttributeDSL:wrap

* [Basic Usage](#basic-usage)
* [Removing Prefixes](#removing-prefixes)
* [Renaming Attributes](#renaming-attributes)
* [Wrapping to Model](#wrapping-to-model)
* [Applying another Mapper](#applying-another-mapper)
* [Wrapping Embedded Attributes](#wrapping-embedded-attributes)
* [Nested Wrapping](#nested-wrapping)
* [Edge Cases](#edge-cases)

See [Unwrapping Tuples](unwrapping.md) for the inverse transformation of data.

Notice, mappers have [high-level and low-level API](../mappers.md#high-level-and-low-level-api). Examples in this section use the high-level API only. The same syntax is applicable to low-level API as well.

Basic Usage
-----------

Suppose there is a predefined relation that returns an array of tuples:

```ruby
users = ROM.env.relations(:users)
users.first
# { id: 1, name: "Joe", contact_email: "joe@example.com", contact_skype: "joe" }
```

With a `wrap` we can take `:contact_email` and `:contact_skype` attributes and convert them into the `:contact` tuple:

### Inline Syntax

```ruby
class WrappedUsersMapper < ROM::Mapper
  register_as :wrapped_users
  relation :users

  wrap contact: [:contact_email, :contact_skype]
end

users.as(:wrapped_users).first
# {
#   id: 1, name: "Joe",
#   contact: { contact_email: "joe@example.com", contact_skype: "joe" }
# }
```

### Block Syntax

Just the same result can be obtained by using the block with attributes defined inside:

```ruby
class WrappedUsersMapper < ROM::Mapper
  register_as :wrapped_users
  relation :users

  wrap :contact do
    attribute :contact_email
    attribute :contact_skype
  end
end
```

Removing Prefixes
-----------------

Use `:prefix` to remove prefixes from wrapped attributes. The `attribute` method arguments should have no prefixes:

### Inline Syntax

```ruby
class WrappedUsersMapper < ROM::Mapper
  register_as :wrapped_users
  relation :users

  wrap :contacts, [:email, :skype], prefix: 'contact'
end

users.as(:wrapped_users).first
# {
#   id: 1, name: "Joe",
#   contacts: { email: "joe@example.com", skype: "joe" }
# }
```

Use `:prefix_separator` in case of a custom separator:

```ruby
user.first
# {
#   id: 1, name: "Joe",
#   :"contact.email" => "joe@example.com", :"contact.skype" => "joe"
# }

class WrappedUsersMapper < ROM::Mapper
  register_as :wrapped_users
  relation :users

  wrap :contacts, [:email, :skype], prefix: 'contact', prefix_separator: '.'
end

users.as(:wrapped_users).first
# {
#   id: 1, name: "Joe",
#   contacts: { email: "joe@example.com", skype: "joe" }
# }
```

### Block Syntax

Inside the block the methods `prefix` and `prefix_separator` will affect attributes following them:

```ruby
class WrappedUsersMapper < ROM::Mapper
  register_as :wrapped_users
  relation :users

  wrap :contact do
    attribute :email

    prefix :contact
    prefix_separator '_'
    attribute :skype
  end
end

users.as(:wrapped_users).first
# {
#   id: 1, name: "Joe",
#   contact: { contact_email: "joe@example.com", skype: "joe" }
# }
```

Renaming Attributes
-------------------

Inside the block use the `:from` option of the [attribute](renaming.md) method:

```ruby
class WrappedUsersMapper < ROM::Mapper
  register_as :wrapped_users
  relation :users

  wrap :contact do
    attribute :to_write, from: :contact_email
    attribute :to_chat,  from: :contact_skype
  end
end
```

**Notice** this feature requires the block syntax. It cannot be done inline.

### Edge Cases

The method works fine when the name of wrapped tuple is the same as one of its attributes. There is no need for renaming attributes.

```ruby
meetings = ROM.env.relation(:meetings)
meetings.first
# { place: "The Conference Hall", agenda: "Future plans", main_thesis: "Bankruptcy" }

class MeetingsMapper < ROM::Mapper
  register_as :wrapped_meetings
  relation :meetings

  wrap :agenda, [:agenda, :thesis]
end

meetings.as(:wrapped_meetings).first
# { place: "The Conference Hall", agenda: { agenda: "Future plans", main_thesis: "Bancrupcy" } }
```

Wrapping to Model
-----------------

Define the [model](models.md) to map wrapped tuple into:

```ruby
require "ostruct"

class UserMapper < ROM::Mapper
  register_as :entity
  relation :users

  wrap :contact do
    model     OpenStruct
    attribute :contact_email
    attribute :contact_skype
  end
end

users.as(:entity).first
# {
#   id: 1, name: "Joe",
#   contact: <OpenStruct contact_email="joe@example.com", contact_skype="joe">
# }
```

**Notice** this feature requires the block syntax. It cannot be done inline.

Applying another Mapper
-----------------------

Another mapper can be applied to wrapped group of attributes. To do this, use the `:mapper` inline option:

```ruby
class ContactMapper < ROM::Mapper
  register_as :contact
  relation :users

  attribute :email, from: :contact_email
  attribute :skype, from: :contact_skype
end

class UserMapper < ROM::Mapper
  register_as :hash
  relation :users

  wrap :contacts, mapper: ContactMapper
end

users.as(:entity).first
# { id: 1, name: "Joe", contacts: { email: "joe@doe.org", skype: "joe" } }
```

Wrapping Embedded Attributes
----------------------------

With the help of [the `embedded` method](embedding), attributes can be wrapped from any level of nested data.

```ruby
class ContactMapper < ROM::Mapper
  register_as :contact
  relation :users

  attribute :email, from: :contact_email
  attribute :skype, from: :contact_skype
end

class UserMapper < ROM::Mapper
  register_as :hash
  relation :users

  embedded :contacts, type: :hash do
    wrap :emails do
      attribute :home, from: :home_email
      attribute :job,  from: :job_email
    end
  end
end

users = ROM.env.relations(:users)
users.first
# {
#   id: 1, name: "Joe",
#   contacts: {
#     home_email: "joe@home.org",
#     job_email: "joe@job.com",
#     skype: "joe"
#   }
# }

users.as(:entity).first
# {
#   id: 1, name: "Joe",
#   contacts: {
#     emails: { home: "joe@home.org", job: "joe@job.com" },
#     skype: "joe"
#   }
# }
```

Nested Wrapping
---------------

Wrappers can be nested deeply. This allows to compact the sequence of transformation steps by doing several wrappings at once.

You can define a corresponding model for any level of nesting:

```ruby
class UserMapper < ROM::Mapper
  register_as :entity
  relation :users

  wrap :contacts do
    model Contacts

    wrap :email do
      model Messages
      attribute :address, from: :contact_email
    end

    wrap :skype do
      model Skype
      attribute :user, from: :contact_skype
    end
  end
end

users.as(:entity).first
# {
#   id: 1, name: "Joe",
#   contacts: <Contacts
#     @email=<Email @address="joe@example.com">,
#     @skype=<Skype @user="joe">
#   >
# }
```

Notice in the example above we mentioned every wrapped attribute (`:address` and `:user`) only once, while they were wrapped at two levels. You haven't to list attributes at any level of wrapping, only at the deepest one.

Edge Cases
----------

### Rejecting Keys

The method `wrap` provides its output regardless of the `reject_keys` setting:

```ruby
class WrappedUsersMapper < ROM::Mapper
  register_as :wrapped
  relation :users
  reject_keys false # is set by default

  wrap :contacts, [:email, :skype], prefix: 'contact'
end

users.as(:wrapped_users).first
# {
#   id: 1, name: "Joe",
#   contacts: { email: "joe@example.com", skype: "joe" }
# }
```

When a `reject_keys` is set to `true`, the `wrap` method defines attributes by itself:

```ruby
class WrappedUsersMapper < ROM::Mapper
  register_as :wrapped
  relation :users
  reject_keys true

  wrap :contacts, [:email, :skype], prefix: 'contact'
end

users.as(:wrapped_users).first
# { contacts: { email: "joe@example.com", skype: "joe" } }
```

Notice the method *always* removes attributes from the upper-level tuple - even in case they are declared explicitly:

```ruby
class WrappedUsersMapper < ROM::Mapper
  register_as :wrapped
  relation :users
  reject_keys true

  attribute :contact_email
  attribute :contact_skype

  wrap :contacts, [:email, :skype], prefix: 'contact'
end

users.as(:wrapped_users).first
# { contacts: { email: "joe@example.com", skype: "joe" } }
```
