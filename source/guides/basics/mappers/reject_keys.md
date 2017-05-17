Rejecting Keys
==============

By default the mapper returns only those attributes that are
declared explicitly either with [attribute](attribute.md) method,
or inside [group](group.md), [combine](combine.md), [embedded](embedded.md),
or [wrap](wrap.md) declarations. The other keys from the relation tuples will be rejected.

The method [reject_keys]() allows to change this setting and output
all keys from the source relation instead. In some cases this makes sense due to
[performance overhead](profiling) added by mapper when it filters attributes.

**Notice** Before using this option read the [tips and tricks](tips-and-tricks)
section to prevent unexpected behaviour of mapper output.

* [base use](#base-use)
* [tips and tricks](#tips-and-tricks)
* [profiling](#profiling)

Base Use
--------

Suppose there is a relation `users` with diverse keys:

```ruby
users = ROM.env.relation(:users)
users.to_a
# [
#   { id: 1, name: "elder", vacation: "grows in kaliyard" },
#   { id: 2, name: "uncle", place: "Kiev" }
# ]
```

By default the mapper outputs only those attributes, that are defined
explicitly:

```ruby
class UserMapper < ROM::Mapper
  relation :users
  register_as :hash

  attribute :id
  attribute :name
end

users.as(:names).to_a
# [{ id: 1, name: "elder" }, { id: 2, name: "uncle" }]
```

To allow all attributes use the `reject_keys false` method:

```ruby
class UserMapper < ROM::Mapper
  relation :users
  register_as :hash

  reject_keys false
end

users.as(:names).to_a
# [
#   { id: 1, name: "elder", vacation: "grows in kaliyard" },
#   { id: 2, name: "uncle", place: "Kiev" }
# ]
```

Tips and Tricks
---------------

Some methods like [prefix](prefix.md), [symbolize_keys](symbolize_keys.md),
[exclude](#exclude.md) affects only those attributes that are declared explicitly.
Forgetting this limitation can lead to unexpected results when `reject_keys` is set to `false`.

For example, when you use the `prefix` method, remember to list all attributes
that should be prefixed. Otherwise the mapper can provide an output like the following:

```ruby
users = ROM.env.relation(:users)
users.first
# [{ user_id: 1, user_name: "Jane" }]

class UserMapper < ROM::Mapper
  relation :users
  register_as :hash
  reject_keys false
  prefix 'user'

  attribute :name
end

users.as(:hash).first
# [{ user_id: 1, name: "Jane" }]
```

The `:user_id` key remained unchanged because it is not declared as an
attribute, and the `prefix` cannot affect it.

Profiling
---------

@todo Estimate the overhead added by default option
