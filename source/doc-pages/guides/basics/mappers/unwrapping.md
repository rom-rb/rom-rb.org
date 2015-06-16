Unwrapping Attributes
=====================

The method [unwrap] inverses the [wrapping](wrapping) transformation.

* [Basic Usage](#basic-usage)
* [Partial Unwrapping](#partial-unwrapping)
* [Renaming Attributes](#renaming-attributes)
* [Unwrapping Embedded Attributes](#unwrapping-embedded-attributes)
* [Nested Unwrapping](#nested-unwrapping)
* [Edge Cases](#edge-cases)

Notice, mappers have [high-level and low-level API](../mappers.md#high-level-and-low-level-api). Examples in this section use the high-level API only. The same syntax is applicable to low-level API as well.

Basic Usage
-----------

Suppose there is a predefined relation that returns an array of nested tuples:

```ruby
users = ROM.env.relations(:users)
users.first
# { id: 1, name: "Joe", contact: { email: "joe@example.com", skype: "joe" } }
```

With `unwrap` we can remove the `:contact` level of nesting.

### Inline Syntax

```ruby
class UnwrappedUsersMapper < ROM::Mapper
  register_as :unwrapped
  relation :users

  unwrap :contact, [:email, :skype]
end

users.as(:unwrapped).first
# { id: 1, name: "Joe", email: "joe@example.com", skype: "joe" }
```

### Block Syntax

Just the same result can be obtained by using the block with attributes defined inside:

```ruby
class UnwrappedUsersMapper < ROM::Mapper
  register_as :unwrapped
  relation :users

  unwrap :contact do
    attribute :email
    attribute :skype
  end
end
```

Partial Unwrapping
------------------

You can unwrap not all the nested attributes, but subset of them:

```ruby
class UnwrappedUsersMapper < ROM::Mapper
  register_as :unwrapped
  relation :users

  unwrap :contact, [:email]
end

users.as(:unwrapped).first
# { id: 1, name: "Joe", email: "joe@example.com", contact: { skype: "joe" } }
```

Renaming Attributes
-------------------

Inside the block you can use `:from` option to rename unwrapped attributes:

```ruby
class UnwrappedUsersMapper < ROM::Mapper
  register_as :unwrapped
  relation :users

  unwrap :contact do
    attribute :contact_email, from: :email
    attribute :contact_skype, from: :skype
  end
end

users.as(:unwrapped).first
# { id: 1, name: "Joe", contact_email: "joe@example.com", contact_skype: "joe" }
```

You can also use `:from` option with `unwrap` to rename the rest of partially unwrapped attribute:

```ruby
class UnwrappedUsersMapper < ROM::Mapper
  register_as :unwrapped
  relation :users

  unwrap :other_contacts, from: :contacts do
    attribute :email
  end
end

users.as(:unwrapped).first
# {
#   id: 1, name: "Joe", email: "joe@example.com",
#   other_contacts: { skype: "joe" }
# }
```

Unwrapping Embedded Attributes
------------------------------

With the help of [the `embedded` method](embedding), attributes can be unwrapped from any level of nested data.

```ruby
class UnwrappedUsersMapper < ROM::Mapper
  register_as :unwrapped
  relation :users

  embedded :user, type: :hash do
    unwrap :emails do
      attribute :email
    end
  end
end

users = ROM.env.relations(:users)
users.first
# { role: 'admin', user: { name: 'Joe', emails: { email: 'joe@doe.com' } } }
users.as(:unwrapped).first
# { role: 'admin', user: { name: 'Joe', email: 'joe@doe.com' } }
```

Nested Unwrapping
-----------------

Unwrapping can be applied to several layers at once:

```ruby
class UnwrappedUsersMapper < ROM::Mapper
  register_as :unwrapped
  relation :users

  unwrap :user do
    attribute :name
    unwrap :contacts do
      attribute :email
    end
  end
end

users = ROM.env.relations(:users)
users.first
# { role: 'admin', user: { name: 'Joe', contacts: { email: 'joe@doe.com' } } }
users.as(:unwrapped).first
# { role: 'admin', name: 'Joe', email: 'joe@doe.com' }
```

You haven't to list unwrapped attribute more than once. In the example above we mentioned `email` attribute only once, though it was unwrapped at two levels.

Edge Cases
----------

### Rewriting Existing Attributes

In case the attributes it the root has the same names as unwrapped ones, the root attributes will be rewritten:

```ruby
users = ROM.env.relations(:users)
users.first
# { id: 1, name: "Joe", email: "joe@doe.com", contact: { email: "joe@example.com" } }

class UnwrappedUsersMapper < ROM::Mapper
  register_as :unwrapped
  relation :users

  unwrap :contact do
    attribute :email
  end
end

users.as(:unwrapped).first
# { id: 1, name: "Joe", email: "joe@example.com" }
```
