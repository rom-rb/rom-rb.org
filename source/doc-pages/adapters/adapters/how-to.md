## How To Build a ROM Adapter

ROM makes very little assumptions about its adapters that's why it is simple to
build a custom adapter that will provide access to a specific datasource.

A ROM adapter must provide the following components:

* `ROM::Gateway` subclass that implements required interface
* `ROM::Relation` subclass that exposes adapter-specific interface for queries and writing

In addition to that the adapter *may* also provide:

* `ROM::Commands::Create` subclass for `create` operation
* `ROM::Commands::Update` subclass for `update` operation
* `ROM::Commands::Delete` subclass for `delete` operation

Let's build an adapter for a plain Ruby array, because why not.

### Gateway

Adapter's gateway is used by ROM to retrieve datasets and inject them into adapter's
relations as their data-access backends. Here's a simple implementation:

``` ruby
require 'rom'

module ROM
  module ArrayAdapter
    class Gateway < ROM::Gateway
      attr_reader :datasets

      def initialize
        @datasets = Hash.new { |h, k| h[k] = [] }
      end

      def dataset(name)
        datasets[name]
      end

      def dataset?(name)
        datasets.key?(name)
      end
    end
  end
end

gateway = ROM::ArrayAdapter::Gateway.new

users = gateway.dataset(:users)
tasks = gateway.dataset(:tasks)

gateway.dataset?(:users) # true
gateway.dataset?(:tasks) # true
```

This allows ROM to ask for specific datasets from your gateway.

### Relation

Adapter-specific relation must exist because it can provide various features
that only make sense for a concrete adapter. It can automatically forward method
calls to the underlaying dataset in order to expose "native" interface to the
relation.

Since our datasets are just arrays, we can expose various array methods to the
relation using `forward` macro:

``` ruby
module ROM
  module ArrayAdapter
    class Relation < ROM::Relation
      # we must configure adapter identifier here
      adapter :array

      forward :select, :reject
    end
  end
end

users = gateway.dataset(:users)

users << { name: 'Jane' }
users << { name: 'John' }

relation = ROM::ArrayAdapter::Relation.new(gateway.dataset(:users))

relation.select { |tuple| tuple[:name] == 'Jane' }.inspect
# #<ROM::ArrayAdapter::Relation dataset=[{:name=>"Jane"}]>
```

<aside class="well">
Please remember about setting `adapter` identifier - it is used by ROM to infer
component types specific to a given adapter. It's essential during the setup.
</aside>

### Registering Your Adapter

The adapter must register itself under specific identifier which then can be used
to set up ROM components for that particular adapter.

To register your adapter:

``` ruby
ROM.register_adapter(:array, ROM::ArrayAdapter)
```

This is it! Now our array adapter can be setup using ROM:

``` ruby
ROM.setup(:array)

class Users < ROM::Relation[:array]
  def by_name(name)
    select { |user| user[:name] == name }
  end
end

rom = ROM.finalize.env

users = rom.gateways[:default].dataset(:users)

users << { name: 'Jane' }
users << { name: 'John' }

rom.relation(:users).by_name('Jane').to_a
# [{:name=>"Jane"}]
```

### Commands

Adapter commands are optional because you don't always want to change data in a
given datastore. If your datastore supports create/update/delete operations you
can provide an interface for that using commands.

ROM adheres to the CQRS but it doesn't enforce it, this means that relations do
implement CRUD and commands are just thin wrappers around CUD and they depend on
relations.

By convention all command classes live under `ROM::YourAdapter::Commands` namespace.

### Common Command Behavior

Every ROM command has a couple of features available out-of-the-box:

* `relation` - returns current relation for the current command
* `source` - original relation that was injected to the current command initially
* `>>(other)` - composes one command with another
* `with(input)` - auto-curries a command with provided input
* `combine(*others)` - builds a command graph with other commands as nodes
* `one?` - returns true if a command returns a single tuple
* `many?`- returns true if a command returns more than one tuple

### Extending Relation for Commands

Commands will require an interface to insert, delete and update data and also
`count`.

Let's provide that:

``` ruby
module ROM
  module ArrayAdapter
    class Relation < ROM::Relation
      adapter :array

      # reading
      forward :select, :reject

      # writing
      forward :<<, :delete

      def count
        dataset.size
      end
    end
  end
end
```

### Commands::Create

To implement a create command:

``` ruby
require 'rom/commands/create' # require what you require!

module ROM
  module ArrayAdapter
    module Commands
      class Create < ROM::Commands::Create
        # Just like in case of Relation, we must configure adapter identifier
        adapter :array

        def execute(tuples)
          tuples.each { |tuple| relation << tuple }
        end
      end
    end
  end
end

users = ROM::ArrayAdapter::Relation.new(gateway.dataset(:users))
create_users = ROM::ArrayAdapter::Commands::Create.new(users)

create_users.call([{ name: 'Jane' }])

puts users.to_a.inspect
# [{:name=>"Jane"}]
```

### Commands::Delete

To implement a delete command:

``` ruby
require 'rom/commands/delete'

module ROM
  module ArrayAdapter
    module Commands
      class Delete < ROM::Commands::Delete
        adapter :array

        def execute
          relation.each { |tuple| source.delete(tuple) }
        end
      end
    end
  end
end

delete_users = ROM::ArrayAdapter::Commands::Delete.new(users)

delete_users.call

puts users.to_a.inspect
# []
```

Notice that here delete command yields tuples from its current `relation` but
deletes it from the `source` relation, since this is our canonical source of data.

### Commands::Update

To implement an update command:

``` ruby
require 'rom/commands/update'

module ROM
  module ArrayAdapter
    module Commands
      class Update < ROM::Commands::Update
        adapter :array

        def execute(attributes)
          relation.each { |tuple| tuple.update(attributes) }
        end
      end
    end
  end
end

update_users = ROM::ArrayAdapter::Commands::Update.new(users)

update_users.call(age: 21)

puts users.to_a.inspect
# [{:name=>"Jane", :age=>21}]
```

Here we simply rely on `Hash#update` which mutates tuples using the input attributes.

### Putting It All Together

Once your command classes are defined ROM will pick them up from your namespace
and they will be available during setup:

``` ruby
ROM.setup(:array)

class Users < ROM::Relation[:array]
  def by_name(name)
    select { |user| user[:name] == name }
  end
end

class CreateUser < ROM::Commands::Create[:array]
  relation :users
  register_as :create
end

class UpdateUser < ROM::Commands::Update[:array]
  relation :users
  result :one
  register_as :update
end

class DeleteUser < ROM::Commands::Delete[:array]
  relation :users
  result :one
  register_as :delete
end

rom = ROM.finalize.env

create_users = rom.command(:users).create
update_user = rom.command(:users).update
delete_user = rom.command(:users).delete

create_users.call([{ name: 'Jane' }, { name: 'John' }])

puts rom.relation(:users).by_name('Jane').to_a.inspect
# [{:name=>"Jane"}]

update_user.by_name('Jane').call(name: 'Jane Doe')

puts rom.relation(:users).to_a.inspect
# [{:name=>"Jane Doe"}, {:name=>"John"}]

delete_user.by_name('John').call

puts rom.relation(:users).to_a.inspect
# [{:name=>"Jane Doe"}]
```
