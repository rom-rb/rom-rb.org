# Setup

Setting up ROM means configuring datastores using adapter-specific configuration
options and defining individual components followed by finalization process.

To setup ROM you use a simple interface which supports a generic syntax for all
adapters; however, each adapter can accept different options.

Here's an example of setting up the in-memory datastore:

``` ruby
ROM.setup(:memory)

# define your components

ROM.finalize
```
Under the hood ROM simply passes provided argument to the corresponding `Datastore`
constructor which is provided by the adapter. In our case it is `ROM::Memory::Datastore`.

You can read more about adapter datastores in [the adapter section](#) of the guides.

## Configuring Many Datastores

You are not limited to only one datastore. If you use more than one datastore you
can simply provide a hash with adapter configuration:

``` ruby
ROM.setup(default: [:sql, 'sqlite::memory'], other: [:yaml, '/path/to/files'])
```

In this case ROM will register two datastore connections called `:default` and
`:other`.

## Defining components

A ROM component is either a relation, command or mapper. After calling `ROM.setup`
you can define the components you want to use in your application.

In example we can define a relation class for our in-memory datastore:

``` ruby
ROM.setup(:memory)

class Users < ROM::Memory[:memory]
end

ROM.finalize
```

## Default and Alternative Datastores

If only one datastore is configured ROM will store it under `:default` name and
it will be used in all relations. If you setup more than one datastore you can
assign relations to individual datastores explicitly:

``` ruby
ROM.setup(default: [:sql, 'sqlite::memory'], other: [:yaml, '/path/to/files'])

# here `:default` is used
class Users < ROM::Relation[:sql]
end

# here we will assign to `:other` explicitly
class Tasks < ROM::Relation[:yaml]
  datastore :other
end

ROM.finalize
```

## Environment

During finalization process ROM instantiates all components based on your class
definitions. Those objects are stored in a registry called ROM's environment.

The environment provides *top-level interface for accessing all components*.

Currently to simplify integration with frameworks like Rails ROM, by default,
stores finalized environment in a globally accessible `ROM.env`.

In example if we defined a relation and a command we can simply access them after
calling `ROM.finalize`:

``` ruby
ROM.setup(:memory)

class Users < ROM::Memory[:memory]
end

class CreateUser < ROM::Commands::Create[:memory]
  relation :users
  register_as :create
  result :one
end

ROM.finalize

rom = ROM.env

# access users relation
rom.relation(:users)

# access user command object
rom.command(:users).create
```
