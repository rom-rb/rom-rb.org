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

Adapter-specific relation must exists because it can provide various features
that only make sense for a concrete adapter. It can automatically forward method
calls to the underlaying dataset in order to expose "native" interface to the
relation.

Since our datasets are just arrays, we can expose various array methods to the
relation using `forward` macro:

``` ruby
module ROM
  module ArrayAdapter
    class Relation < ROM::Relation
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
