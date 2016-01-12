#Using `Relation#combine`
Ordinarily, Relation is used through Repository, but some applications may use Relation directly. 
This removes the layer of syntactic sugar provided by Repository, and so `#combine` must be handled directly.

```ruby
class Users < ROM::Relation[:memory]
  def by_name(name)
    restrict(name: name)
  end
end

class Tasks < ROM::Relation[:memory]
  def for_users(users)
    restrict(user_id: users.map { |u| u[:id] })
  end
end


rom_container = ROM.container(:sql) do |rom|
  rom.register_relation(Users, Tasks)
end

users = rom_container.relation(:users)
tasks = rom_container.relation(:tasks)

# combine two relations into one
users.by_name('Jane').combine(tasks.for_users)
```