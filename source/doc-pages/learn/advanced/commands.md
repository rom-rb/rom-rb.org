# Standalone Commands

Writing records to a persistence solution is done through Commands. Commands are objects that encapsulate
datastore-specific modification operations. They receive a relation and execute their operation using that
relation.

ROM adapters can provide three basic Command types:

* `ROM::Commands::Create`
* `ROM::Commands::Update`
* `ROM::Commands::Delete`

Some adapters provide more for special operations - see your adapter’s documentation for details.

## Defining Commands

In your setup, define available commands with the `commands` statement, passing it a symbol of the relation's name:

```ruby
require 'rom-repository'

# Assumes a database with a users table
ROM.container(:sql, 'sqlite::memory') do |rom|
 # Remember that many adapters can infer relations, so we can often skip defining it.
 # Otherwise, add something like:
 #
 # rom.relation(:users)

 rom.commands(:users) do
    # declares that we can create, update, and delete users.
    define(:create)
    define(:update)
    define(:delete)
 end
end
```

#### Single Results vs Many Results

Ordinarily, a command will return an `Array` of `Hash` objects. You can customize
this to return a single result by supplying `result :one` to the command definition.

```ruby
ROM.container(:sql, 'sqlite::memory') do |rom|
  rom.commands(:users) do
    define(:create) do
       result :one
    end

    # ... etc
  end
end
```

## Executing Commands

Every registered command is accessible through the environment container:

```ruby
rom_container = ROM.container(:sql, 'sqlite::memory') do |rom|
  rom.relation(:users) do
    def by_id(id)
      where(id: id)
    end

    def by_first_name(name)
      where(first_name: name)
    end
  end

  rom.commands(:users) do
    define(:create)
  end
end

# fetch the command object by type
create_user = rom_container.commands[:users][:create]

# a command object won’t do anything until it’s called with input tuples:
new_users = [
  { name: 'Jane' },
  { name: 'Joe' }
]

create_user.call(new_users) # saves the user tuples
```

Commands are backed by a relation, which you can use to specify which records to
Update or Delete.

```ruby
# operate on a single result
delete_user = rom_container.commands[:users][:delete]

delete_user.by_id(2).call

# or many
delete_users = rom_container.commands[:users][:delete]

delete_users.by_first_name(first_name: 'Lawrence').call

# update is the same, and takes the new data as a parameter to #call
update_user = rom_container.command[:users][:update]

update_user.by_id(7).call(first_name: 'Kaylee', last_name: 'Frye')
```

## Full Example

This short example demonstrates defining and using the three basic commands.

```ruby
# app.rb
class MyApp
  def self.run(rom_container)
    user_commands = rom_container.commands[:users]

    # Create...
    user = user_commands[:create].call(first_name: 'Natalia', last_name: 'Romanova')

    puts rom_container.relation(:users).to_a.inspect
    # => [{:first_name=>"Natalia", :last_name=>"Romanova"}]

    # Update...
    user_commands[:update].by_id(user[:id]).call(first_name: 'Natasha', last_name: 'Romanoff')

    puts rom_container.relation(:users).to_a.inspect
    # => [{:first_name=>"Natasha", :last_name=>"Romanoff"}]

    # And Delete!
    user_commands[:delete].by_id(user[:id]).call

    puts rom_container.relation(:users).to_a.inspect
    # => []
  end
end
```

```ruby
# command_demo.rb
require 'rom-sql'

# Assumes a database with a users table
rom_container = ROM.container(:sql, 'sqlite::memory') do |rom|
  rom.use :macros

  rom.relation(:users) do
    def by_id(id)
      restrict(id: id)
    end
  end

  rom.commands(:users) do
    define(:create) do
       result :one
    end

    define(:update)

    define(:delete)
  end
end

MyApp.run(rom_container)
```

Run it and see the three states print out.

```bash
ruby command_demo.rb
```
