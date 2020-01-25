---
chapter: Advanced
title: Explicit Setup
---

Block style setup is suitable for simple, quick'n'dirty scripts that need to
access databases, in a typical application setup, you want to break down
individual component definitions, like relations or commands, into separate
files and define them as explicit classes.

> ROM & Frameworks
>
> Framework integrations **take care of the setup for you**. If you want to use ROM
> with a framework, please refer to specific instructions under [Getting Started](/%{version}/learn/getting-started)
> section

## Setup

To do setup in flat style, create a `ROM::Configuration` object. This is the
same object that gets yielded into your block in block-style setup, so the API
is identical.

```ruby
configuration = ROM::Configuration.new(:memory, 'memory://test')
configuration.relation(:users)
# ... etc
```

When you’re finished configuring, pass the configuration object to
`ROM.container` to generate the finalized container. There are no differences in
the internal semantics between block-style and flat-style setup.

### Registering Components

ROM components need to be registered with the ROM configuration in order to be used.

```ruby
configuration = ROM::Configuration.new(:memory, 'memory://test')

# Declare Relations, Commands, and Mappers here
```

If you prefer to create explicit classes for your components you must register
them with the configuration directly:

```ruby
configuration = ROM::Configuration.new(:memory, 'memory://test')

configuration.register_relation(OneOfMyRelations)
configuration.register_relation(AnotherOfMyRelations)
configuration.register_command(User::CreateCommand)
configuration.register_mapper(User::UserMapper)
```

You can pass multiple components to each `register` call, as a list of arguments.

### Auto-registration

ROM provides `auto_registration` as a convenience method for automatically
`require`-ing and registering components that are not declared with the DSL. At
a minimum, `auto_registration` requires a base directory. By default, it will
load relations from `<base>/relations`, commands from `<base>/commands`, and
mappers from `<base>/mappers`.

#### Namespaces inferred from directory structure

By default, auto-registration assumes that the directory structure reflects your module/class
organization, for example:

``` ruby
# lib/relations/users.rb
module Relations
  class Users < ROM::Relation[:sql]
    schema(infer: true)
  end
end

# lib/relations
```

Then to set up auto-registration simply provide the root path to your components directory:

```ruby
configuration = ROM::Configuration.new(:memory)
configuration.auto_registration('/path/to/lib')
container = ROM.container(configuration)
```

#### Explicit namespace name

If your directory structure doesn't reflect module/class organization but you do namespace components,
then you can set up auto-registration via `:namespace` option:

``` ruby
# lib/relations/users.rb
module Persistence
  module Relations
    class Users < ROM::Relation[:sql]
      schema(infer: true)
    end
  end
end
```

Since we use `Persistence` as our namespace, we need to set it explicitly:

```ruby
configuration = ROM::Configuration.new(:memory)
configuration.auto_registration('/path/to/lib', namespace: 'Persistence')
container = ROM.container(configuration)
```

#### Turning namespace off

If you keep all components under `{path}/(relations|commands|mappers)` directories and don't
namespace them, then you can simply turn namespacing off:

``` ruby
# lib/relations/users.rb
class Users < ROM::Relation[:sql]
  schema(infer: true)
end
```

```ruby
configuration = ROM::Configuration.new(:memory)
configuration.auto_registration('/path/to/lib', namespace: false)
container = ROM.container(configuration)
```

## Relations

Relations can be defined with a class extending `ROM::Relation` from the appropriate adapter.

```ruby
# Defines a Users relation for the SQL adapter
class Users < ROM::Relation[:sql]

end

# Defines a Posts relation for the HTTP adapter
class Posts < ROM::Relation[:http]

end
```

Relations can declare the specific [gateway](/learn/introduction/glossary#gateway) and [dataset](/learn/introduction/glossary/#dataset) it takes data from, as well as the registered name of the relation. The following example sets the default options explicitly:

```ruby
class Users < ROM::Relation[:sql]
  register_as :users    # the registered name; eg. for use in Repository’s relations(...) method
  gateway :default      # the gateway name, as defined in setup
  dataset :users        # eg. in sql, this is the table name
end
```

## Commands

Just like Relations, Commands can be defined as explicit classes:

```ruby
class CreateUser < ROM::Commands::Create[:memory]

end
```

Commands have three settings: their relation, which takes the registered name of
a relation; their result type, either `:one` or `:many`; and their registered
name.

```ruby
class CreateUser < ROM::Commands::Create[:memory]
   register_as :create
   relation :users
   result :one
end
```

> Typically, you're going to use [repository command interface and changesets](/%{version}/learn/repositories/quick-start);
> custom command classes are useful when the built-in command support in
> repositories doesn't meet your requirements
