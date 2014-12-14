ROM uses adapters to connect to different data sources (a database, a csv file -
it doesn't matter) and exposes a native CRUD interface to its relations. This
interface is considered private and should only be used within relation methods
and commands.

This means ROM doesn't have an abstract query interface that every adapter must
implement - even though it could be an elegant solution it requires a lot of
additional complexity that ROM tries to avoid. It's a trade-off but there's a
great benefit coming with this approach too - you have access to powerful query
interfaces provided by adapters without any overhead of unnecessary abstractions.

In addition to native interfaces ROM makes it possible for an adapter to extend
relations with new behavior. This feature is already used by `rom-sql` where
Sequel's dataset API is extended with convenient methods for joining relations.

### Sample adapter

Believe it or not but an array can be an adapter:

``` ruby
class ArrayAdapter < ROM::Adapter
  def self.schemes
    [:array]
  end

  def initialize(uri)
    super
    @connection = {}
  end

  def dataset(name, _header)
    @connection[name] = []
  end

  def dataset?(name)
    @connection.key?(name)
  end

  def [](name)
    @connection.fetch(name)
  end

  def extend_relation_instance(relation)
    relation.extend(Enumerable)
  end
end

ROM::Adapter.register(ArrayAdapter)

rom = ROM.setup(default: 'array://test') do
  schema do
    base_relation(:users) do
      repository :default
      attribute :name
    end
  end

  relation(:users) do
    def by_name(name)
      find_all { |user| user[:name] == name }
    end
  end
end

rom.schema.users << { name: 'Jane' }

puts rom.relations.users.by_name('Jane').first.inspect
# { :name => 'Jane' }
```
