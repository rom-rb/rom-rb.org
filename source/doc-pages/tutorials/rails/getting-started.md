## Getting started

To get up and running quickly you can generate the app skeleton using a special
template:

``` shell
rails new rom-todo-app -JTS -m http://rom-rb.org/doc-examples/rails-template.rb
```

The template does a couple of things for us:

* Adds required gems to Gemfile
* Generates migrations that create `users` and `tasks` tables
* Generates `app/relations` with users and tasks relations
* Generates `app/mappers` with default definitions for `users` and `tasks`
* Generates `app/commands` with default set of create/update/delete commands for `users`
  and `tasks`
* Creates `spec/fixtures` with basic test data for our specs

Now you should be able to go to the app directory and open the rails console:

``` shell
cd rom-todo-app
bin/rails c

# in the console
rom = ROM.env
rom.command(:users).try { create(name: 'Jane', email: 'jane@doe.org') }
=> #<ROM::Result::Success:0x007fb148755d90 @value={:id=>1, :name=>"Jane", :email=>"jane@doe.org"}>
rom.read(:users).to_a
=> [{:id=>1, :name=>"Jane", :email=>"jane@doe.org"}]
```

As you can see ROM environment object is accessible via `ROM.env`. This is a
convention built specifically for frameworks like Rails where you need a global
access to the environment.

Notice that our mappers don't define any "object mapping" yet so ROM simply
returns hashes.
