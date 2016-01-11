#Reading Simple Records

##Relations
Relations are the basis for reading data. Many adapters, like the popular `rom-sql` will examine your datastore and 
automatically infer default relations for you. Hooray!

Once your application matures, you'll likely need to define relations directly. See the [advanced guide](/learn/advanced) for more. 

##Repositories
A Repository ("Repo") object provides a lot of conveniences for reading data with relations.

You need to explicitly declare which `relations` it needs access to:

```ruby
require 'rom-repository'

# Assuming a database with table 'users'
rom_container = ROM.container(:sql, 'sqlite::memory') 

class MyRepository < ROM::Repository::Base
   relations :users
   
   # ... selector methods will go here. We'll discuss those later
end

user_repo = MyRepository.new(rom_container)

user_repo.users.to_a
# => []
```

Depending on how complex your application becomes, you may want to create separate Repository classes to 
subdivide duties.
 
```ruby
# Assuming a database with tables 'users' and 'projects'
rom_container = ROM.container(:sql, 'sqlite::memory') 

# Perhaps one Repo to handle users and related authentication relations
class UsersRepository < ROM::Repository::Base
   relations :users
   
   # ... [users-related selector methods go here]
end

# Another repository could handle the projects and related concepts
class ProjectRepository < ROM::Repository::Base
   relations :projects
   
   # ... [project-related selector methods go here]
end

user_repo = UserRepository.new(rom_container)
project_repo = ProjectRepository.new(rom_container)

# now we can pass both repositories into your app
MyApp.run(user_repo, project_repo)
```

###Selector Methods
While defining a Repository, you will also define its methods for domain-specific queries. These are called 
**selector methods**.

They use the querying methods provided by the adapter to accomplish their task. For example, the 
`rom-sql` adapter provides methods like `Relation#where`.

```ruby
class MyRepository  
   # declaring :users here makes the #users method available
   relations :users
   
   # find all users with the given attributes
   def users_with(attributes_hash)
      users.where(attributes_hash)
   end
   
   # collect  a list of all user ids
   def user_id_list
      users.to_a.collect {|user| user[:id]}
   end
end
```

Read your adapter's documentation to see the full listing of its Relation methods. 

<aside class="well">
These are just simple reads. See the <a href="/learn/associations">Associations</a> section to see how to construct multi-relation selector methods.
 </aside>


####Single Results vs Many Results
Every relation is lazy loading and most methods return another relation. To enact the relation query and get actual data, use `#one`, `#one!`, or `#to_a`. 

```ruby 
# Produces a single tuple. 
# Raises an error if there are 0 results
users.one

# Produces a single tuple. 
# Raises an error if there are 0 results or more than one
users.one!

# Produces an array of tuples, possibly empty. 
users.to_a
```

##Full Example
This short example demonstrates using selector methods, #one, and #to_a.


```ruby
require 'rom-repository'

rom_container = ROM.container(:sql, 'sqlite::memory') do |rom|
   rom.use :macros

   rom.relation(:users)
end

class MyRepository < ROM::Repository::Base
   relations :users # this makes the #users method available

   # selector methods
   def users_with(params)
      users.where(params).to_a
   end
   
   def user_by_id(id)
      users.where(id: id).one!
   end 
   
   # ... etc
end

MyApp.run(rom_container, MyRepository.new(rom_container))
```

And then in our app we can use the selector methods:

```ruby
# assuming that there is already data present

repository.users_with(first_name: 'Malcolm', last_name: 'Reynolds')
#=> [ROM::Struct[User] , ROM::Struct[User], ...]

repository.user_by_id(1)
#=> ROM::Struct[User]
```

