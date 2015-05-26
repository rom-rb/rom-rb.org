# Commands

In ROM commands are objects encapsulating datastore-specific create, update and
delete operations. A command receives a relation and executes its operation against
that relation.

ROM supports three type of commands:

- `ROM::Commands::Create`
- `ROM::Commands::Update`
- `ROM::Commands::Delete`

It is possible for a given adapter to provide more types.

## Defining a command

A command can be defined as a class that inherits from an adapter-specific class
which is identified by adapter's name, in case of our example it's `:memory`:

``` ruby
class CreateUser < ROM::Commands::Create[:memory]
  relation :users
  register_as :create
end
```

By setting `register_as` we're telling ROM how the command should be named in the
environment, you can use whatever name you want and you can register as many
commands as you wish.

## Accessing commands

Every registered command is accessible through the environment:

``` ruby
ROM.setup :memory

class CreateUser < ROM::Commands::Create[:memory]
  relation :users
  register_as :create
end

ROM.finalize

rom = ROM.env

create_user = rom.command(:users).create
```

## Calling Commands

A command object doesn't do anything until it's called with input tuples:

``` ruby
new_users = [
  { name: 'Jane' },
  { name: 'Joe' }
]

create_user.call(new_users) # returns created users
```

## Configuring Commands

By default command returns an array of resulting tuples. You can change it to
just return a single tuple via `result` interface:

``` ruby
ROM.setup :memory

class CreateUser < ROM::Commands::Create[:memory]
  relation :users
  register_as :create
  result :one
end

ROM.finalize

rom = ROM.env

create_user = rom.command(:users).create

create_user.call(name: 'Jane') # returns a single tuple
```

### Specifying Relation For A Command

You can set specific relation for a command using your own interface:

``` ruby
ROM.setup :memory

class Users < ROM::Relation[:memory]
  def by_id(id)
    restrict(id: id)
  end
end

class DeleteUser < ROM::Commands::Delete[:memory]
  relation :users
  register_as :delete
  result :one
end

ROM.finalize

rom = ROM.env

delete_user = rom.command(:users).delete

# narrows down the relation to users with matching id and deletes them
delete_user.by_id(1).call
```

## Composing Commands

Multiple commands can be composed into a pipeline using common `>>` operator:

``` ruby
ROM.setup :memory

class CreateUser < ROM::Commands::Create[:memory]
  relation :users
  register_as :create
  result :one
end

class CreateTask < ROM::Commands::Create[:memory]
  relation :users
  register_as :create

  def execute(tasks, user)
    tuples = tasks.map { |t| t.merge(user_id: user[:id] }
    super(tuples)
  end
end

ROM.finalize

rom = ROM.env

create_tasks = rom.command(:tasks).create
create_user = rom.command(:users).create

new_user = { name: 'Jane' }
new_tasks = [{ title: 'One' }, { title: 'Two' }]

command = create_user.with(new_user) >> create_tasks.with(new_tasks)

# creates a user, passes to create_tasks which creates tasks and return them
command.call
```

### Mapping Command Result

You can use a custom mapper to pipe results of a command using `>>` operator or
register a mapper and refer to its name using common `as` or `map_with` interface:

``` ruby
ROM.setup :memory

class CreateUser < ROM::Commands::Create[:memory]
  relation :users
  register_as :create
  result :one
end

class UserMapper < ROM::Mapper
  relation :users
  register_as :entity

  model MyEntities::User
end

ROM.finalize

rom = ROM.env

create_user = rom.command(:users).as(:entity).create

new_user = { name: 'Jane' }

# creates a user and maps it using `:entity` mapper
create_user.call(new_user)
```
