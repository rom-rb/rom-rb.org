---
title: Flat Style Setup
chapter: Advanced Topics
---

# Flat Style Setup

Block style setup is suitable for simple, quick'n'dirty scripts that need to
access databases, in a typical application setup, you want to break down
individual component definitions, like relations or commands, into separate
files.

**Framework integrations take care of the setup for you. If you want to use ROM
with a framework, please refer to [frameworks](/learn/frameworks) section.**

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

ROM components need to be registered with the ROM environment in order to be
used.

The `:macros` plugin handles this behind the scenes for you whenever you use the
DSL to declare a ROM component. As of version 1.0.0 it is enabled by default:

```ruby
configuration = ROM::Configuration.new(:memory, 'memory://test')

# Anything after this line will be automatically registered
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

You can pass multiple components to each `register` call, as a list of
arguments.

### Auto-registration

ROM provides `auto_registration` as a convenience method for automatically
`require`-ing and registering components that are not declared with the DSL. At
a minimum, `auto_registration` requires a base directory. By default, it will
load relations from `<base>/relations`, commands from `<base>/commands`, and
mappers from `<base>/mappers`.

```ruby
configuration = ROM::Configuration.new(:memory)
configuration.auto_registration(__dir__)
container = ROM.container(configuration)
```

By default, it assumes that each class is in the root namespace. A `namespace` option can be provided if that is not the case. Finally, the file name and the name of the constant must match.

```ruby
configuration = ROM::Configuration.new(:memory)
configuration.auto_registration(__dir__, namespace: "MyApp")
container = ROM.container(configuration)
```

```ruby
configuration = ROM::Configuration.new(:memory)
configuration.auto_registration(__dir__, namespace: "MyApp", relations: {namespace: "MyApp::Relations"})
container = ROM.container(configuration)
```

## Relations

Relations are the interface to get data out of your persistence solution. They
represent groups of data; in a database scenario, these are equivalent to
tables.

As your application grows in scope or complexity, you will likely want to DRY up
common logic from your Repository class(es) into Relations. In other situations,
you may also use Relations directly - Repository is just a convenience, not a
requirement.

While the DSL syntax is often convenient, Relations can also be defined with a
class extending `ROM::Relation` from the appropriate adapter.

```ruby
# Defines a Users relation for the SQL adapter
class Users < ROM::Relation[:sql]

end
```

Relations can declare the specific
[gateway](http://rom-rb.org/introduction/glossary/#gateway) and
[dataset](http://rom-rb.org/introduction/glossary/#dataset) it takes data from,
as well as the registered name of the relation. The following example sets the
default options explicitly:

```ruby
class Users < ROM::Relation[:sql]
  register_as :users    # the registered name; eg. for use in Repository’s relations(...) method
  gateway :default      # the gateway name, as defined in setup
  dataset :users        # eg. in sql, this is the table name
end
```

## Commands

Just like Relations, Commands have an alternative style as a regular class:

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
