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


This is made possible by the auto-currying feature. 

##Auto-Curry
Every relation method that you defined supports auto-curry syntax. *Currying* means that you can reference a Relation 
and provide method arguments later:

```ruby
users_by_name = rom.relation(:users).by_name

# call later on using short `[]` syntax
users_by_name['Jane']

# or more explicitly
users_by_name.call('Jane')
```