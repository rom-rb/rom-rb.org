# Commands

In ROM commands are objects encapsulating datastore-specific create, update and
delete operations. A command receives a relation and executes its operation against
that relation.

ROM supports three type of commands:

- `ROM::Commands::Create`
- `ROM::Commands::Update`
- `ROM::Commands::Delete`

It is possible for a given adapter to provide more types.

Commands are small, well encapsulated objects, this makes it possible to compose
them into a command graph which can persist data coming from many relations with
a single call.

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

The same technique is used with update commands.

``` ruby
# Define update command in setup, as with DeleteUser above
class UpdateUser < ROM::Commands::Update[:memory]
  relation :users
  register_as :update
  result :one
end

# Update user 1, setting `foo` to `"bar"`
rom.command(:users).update.by_id(1).call(foo: "bar")
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

### Combining Multiple Commands into a Command Graph

Multiple commands can be combined together into a graph that can work with a nested
input attributes. This is similar to combining relations except that returned
data is a result of executing commands.

To build a command graph you can pass an array with options to the common command
interface:

``` ruby
require 'rom'

ROM.setup(:memory)

ROM.relation(:users)
ROM.relation(:tasks)

class CreateUser < ROM::Commands::Create[:memory]
  relation :users
  register_as :create
  result :one

  # filter out stuff we don't need
  input Transproc(:accept_keys, [:id, :name])
end

class CreateTask < ROM::Commands::Create[:memory]
  relation :tasks
  register_as :create

  # filter out stuff we don't need
  input Transproc(:accept_keys, [:user_id, :title])

  def execute(tasks, user)
    tuples = tasks.map { |t| t.merge(user_id: user[:id]) }
    super(tuples)
  end
end

ROM.finalize

rom = ROM.env

user_with_tasks = {
  user: {
    id: 1,
    name: 'Jane',
    tasks: [
      { title: 'Task One' },
      { title: 'Task Two' }
    ]
  }
}

create_user_with_tasks = rom.command([
  { user: :users }, [:create, [:tasks, [:create]]]
])

create_user_with_tasks.call(user_with_tasks)
# {:id=>1, :name=>"Jane"}
# {:title=>"Task One", :user_id=>1}
# {:title=>"Task Two", :user_id=>1}
```

The structure of the array with options is following:

```
# when key in the input matches relation name
[
  :name_of_your_relation, [:name_of_your_relation_command]
]

# when key in the input doesn't match relation name
[
  { key_in_the_input: name_of_your_relation }, [
    :name_of_your_relation_command
  ]
]
```

This can be nested however you like and used with commands that return either
`:one` or `:many` results.

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

This works with a single command, composed commands and command graphs.
