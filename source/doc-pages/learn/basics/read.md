#Reading Simple Records

##Relations
Relations are the basis for reading data. Many adapters, like the popular `rom-sql` will examine your datastore and 
automatically define a default relation for you. Hooray!

Once your application matures, you'll likely need to define relations directly. See the [advanced guide](/learn/advanced) for more. 

##Repositories
A Repository object provides a lot of conveniences for reading data with ROM’s fundamental building block of 
relations.

You need to explicitly declare which `relations` it manages:

```ruby
require rom-repository

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
# Perhaps one to handle users and related authentication relations
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


