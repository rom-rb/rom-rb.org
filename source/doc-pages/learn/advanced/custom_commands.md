#Advanced - Custom Commands

There are some adapters that add base commands, but you can also define your own. 

```ruby
class UpsertUser < ROM::Commands::Create[:memory]
  relation :users
  register_as :upsert
  
  def execute
     # do the operations to create a new record or update an existing one
  end
end
```