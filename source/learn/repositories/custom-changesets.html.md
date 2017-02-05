---
chapter: Repositories
title: Custom Changesets
---

You can define custom changeset classes that should inherit from one of the built-in
types:

- `ROM::Changeset::Create` uses `Create` commands
- `ROM::Changeset::Update` uses `Update` commands
- `ROM::Changeset::Delete` uses `Delete` commands
- `ROM::Changeset` is a generic type that needs to be configured with a specific command type that you'd like to use

## Defining Changeset subclass for a specific relation

Let's say we want to generate a random access token for a user prior saving its changeset. To achieve this we can
set up a custom changeset class that will do just that:

``` ruby
require 'securerandom'

class NewUserChangeset < ROM::Changeset::Create[:users]
  map do |tuple|
    tuple.merge(access_token: generate_access_token)
  end

  def generate_access_token
    SecureRandom.hex
  end
end
```

Now we can easily use this changeset with a user repository:

``` ruby
new_user = user_repo.changeset(NewUserChangeset).data(name: 'Jane')

user_repo.create(new_user)
# => #<ROM::Struct[User] id=1 name="Jane" access_token="b9dd175aec90758b0841d09e4947724e">
```

## Re-using base changeset classes

You can inherit from your own base changeset classes to re-use common functionality.
For example you may want to generate access_tokens for admins and users that are separate
entities within your system. To achieve this you can define base changeset class
without setting it up for any specific relation:

``` ruby
require 'securerandom'

class NewUserChangeset < ROM::Changeset::Create
  map do |tuple|
    tuple.merge(access_token: generate_access_token)
  end

  def generate_access_token
    SecureRandom.hex
  end
end
```

Now we can ask specific root repositories for instances of this changeset:

``` ruby
new_user = user_repo.changeset(NewUserChangeset).data(name: 'Jane')

user_repo.create(new_user)
# => #<ROM::Struct[User] id=1 name="Jane" access_token="b9dd175aec90758b0841d09e4947724e">

new_admin = admin_repo.changeset(NewUserChangeset).data(name: 'Jane')

admin_repo.create(new_admin)
# => #<ROM::Struct[Admin] id=1 name="Jane" access_token="b9dd175aec90758b0841d09e4947724e">
```

### Using Dependency Injection with changesets

If you want to reuse various components in your changesets without coupling them too much, you can use `option` API
to define additional changeset collaborators. Let's say we want to provide a token generator as a changeset's collaborator
instead of implementing additional method in our changeset:

``` ruby
class NewUserChangeset < ROM::Changeset::Create
  option :token_generator, reader: true

  map do |tuple|
    tuple.merge(access_token: token_generator.call)
  end
end

new_user = user_repo.
  changeset(NewUserChangeset).
  with(token_generator: SecureRandom.method(:hex).
  data(name: 'Jane')

user_repo.create(new_user)
# => #<ROM::Struct[User] id=1 name="Jane" access_token="b9dd175aec90758b0841d09e4947724e">
```
