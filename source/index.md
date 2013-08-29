---
title: Ruby Object Mapper
---

# Ruby Object Mapper

### 1. Set up environment and define schema

```ruby
  require 'rom'
  require 'rom/support/axiom/adapter/memory'
  require 'axiom-memory-adapter'

  env = ROM::Environment.setup(memory: 'memory://test')

  env.schema do
    base_relation :users do
      repository :memory

      attribute :id,   Integer
      attribute :name, String

      key :id
    end
  end
```

### 2. Set up mapping

```ruby
  class User
    attr_reader :id, :name

    def initialize(attributes)
      @id, @name = attributes.values_at(:id, :name)
    end
  end

  env.mapping do
    users do
      map :id, :name
      model User
    end
  end
```

### 3. Work with Plain Old Ruby Objects

```ruby
  ROM::Session.start(env) do |session|
    user = session[:users].neOM::Session.start(env) do |session|
  user = session[:users].new(id: 1, name: 'Jane')
  session[:users].save(user)
  session.flush
end

jane = env[:users].restrict(name: 'Jane').one
    session[:users].save(user)
    session.flush
  end

  jane = env[:users].restrict(name: 'Jane').one
```
