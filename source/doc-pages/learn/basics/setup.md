# Setup

<aside class="well">
   Note: All guide examples are written specifically for the <code>rom-sql</code> adapter. 
   If you are using a different one, consult that adapter's documentation too.
</aside>

In order to integrate ROM adapters and components into your app, ROM requires a setup phase.

The general shape of the setup phase involves the following three steps:

- Configure a [gateway](/introduction/glossary/#gateway) with adapter-specific options
- Define the individual relation, mapper and command components
- Finalize the environment

To setup ROM you use a simple interface which supports a generic syntax for all
adapters; however, each adapter can accept different options.

Here's an example of setting up the in-memory gateway:

``` ruby
ROM.setup(:memory)

# define your components

ROM.finalize
```

Under the hood ROM simply passes provided argument to the corresponding `Gateway`
constructor which is provided by the adapter. In our case it is `ROM::Memory::Gateway`.

You can read more about adapter gateways in [the adapter guide](/guides/adapters).

## Configuring Many Gateways

You are not limited to only one gateway. If you use more than one gateway you
can simply provide a hash with adapter configuration:

``` ruby
ROM.setup(
  default: [:sql, 'sqlite::memory'],
  other: [:csv, '/path/to/files', { encoding: 'utf-8', col_sep: ';' }]
)
```

In this case ROM will register two gateway connections called `:default` and
`:other`.

## Defining components

A ROM component is either a relation, command or mapper. After calling `ROM.setup`
you can define the components you want to use in your application.

In example we can define a relation class for our in-memory gateway:

``` ruby
rom = ROM.setup(:memory)

class Users < ROM::Relation[:memory]
end

rom.register_relation(Users)

ROM.finalize
```

## Default and Alternative Gateways

If only one gateway is configured ROM will store it under `:default` name and
it will be used in all relations. If you setup more than one gateway you can
assign relations to individual gateway explicitly:

``` ruby
rom = ROM.setup(
  default: [:sql, 'sqlite::memory'],
  other: [:csv, '/path/to/files', { encoding: 'utf-8', col_sep: ';' }]
)

# here `:default` is used
class Users < ROM::Relation[:sql]
end

# here we will assign to `:other` explicitly
class Tasks < ROM::Relation[:csv]
  gateway :other
end

rom.register_relation(Users)
rom.register_relation(Tasks)

ROM.finalize
```

## Container

During finalization process ROM instantiates all components based on your class
definitions. Those objects are stored in a registry called ROM container.

The container provides *top-level interface for accessing all components*.

Currently to simplify integration with frameworks like Rails ROM, by default,
stores finalized container in a globally accessible `ROM.env`.

In example if we defined a relation and a command we can simply access them after
calling `ROM.finalize`:

``` ruby
ROM.use :auto_registration

rom = ROM.setup(:memory)

class Users < ROM::Relation[:memory]
end

class CreateUser < ROM::Commands::Create[:memory]
  relation :users
  register_as :create
  result :one
end

rom = ROM.finalize.env

# access users relation
rom.relation(:users)

# access user command object
rom.command(:users)[:create]
```
