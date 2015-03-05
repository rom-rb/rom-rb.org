## Getting started

_Note: You'll need a newish version of Rails installed and available to make this
all work._

First, we need to create a new Rails application. To get up and running quickly
we've provided a small [application template](https://github.com/rom-rb/rom-rb.org/blob/master/source/tutorials/code/rom-todo-app-template.rb) which takes care of a few details.

Open up a console and create a new Rails application with the following commands:

``` shell
wget http://rom-rb.org/tutorials/code/rom-todo-app-template.rb
rails new rom-todo-app -JTS -m rom-todo-app-template.rb
```

Once this is finished, change to the new application directory and open a Rails console:

```shell
cd rom-todo-app
bin/rails console
```

Hooray! You’ve now got a working Rails app with an integration to ROM.

Before diving into the structure of the app itself, let’s explore the different parts of the 
ROM API from within the Rails console.

### Access the ROM environment

The environment is provided specifically for frameworks like Rails where you need
global access to the ROM registry.

```ruby
rom = ROM.env
```

By default, the environment is configured with an SQLite repository and the registry of relations, mappers and commands.

### Working with ROM objects

The Rails template introduces a convention for managing objects provided by ROM alongside the familiar Rails conventions.

Commands, mappers, and relations are autoloaded and registered with the ROM environment when placed in the following locations:

- `app/commands`
- `app/mappers`
- `app/relations`

If you look inside these paths in the Rails app, you’ll see that the application template generated a `tasks.rb` file in each of these paths as well as a `*_create_tasks.rb` migration in `db/migrations`.

Use the following methods to look up the registered task objects on the environment:

```ruby
rom.commands
rom.mappers
rom.relations
```

### Get the list of tasks

To get the list of tasks, we get the relation from the registry and call `to_a`, which executes the query and returns an array of results:

```ruby
rom.relation(:tasks).to_a
```

We should get back an empty array here because the database is currently empty.

### Use a command to create a task

Create a new task by getting the create command from the registry and calling it with a hash of attributes to save:

```ruby
rom.command(:tasks).create.call(text: 'finish the rom-rails tutorial')
```

The `create` method accepts a hash of attributes to be saved, and returns a result object representing the created task.

### Read back the task we just created

Look up the tasks relation again, and materialize it to an array:

```ruby
rom.relation(:tasks).to_a
```

We haven’t yet defined a mapper or added any queries to the relation so all we can do at this point is read back the entire list of tasks as an array of hashes.

Relations always return immutable collections supporting Ruby’s [Enumerable](http://ruby-doc.org/core-2.2.0/Enumerable.html) interface. Test this out by trying some of the following operations in the Rails console:

```ruby
rom.relation(:tasks).first

rom.relation(:tasks).count

rom.relation(:tasks).each { |t| puts t[:text] }

rom.relation(:tasks).map { |t| t[:id] }

rom.relation(:tasks).detect { |t| t[:text].match(/rom/) }
```

But with nothing more than an empty relation defined, there’s not a lot we can do in terms of querying this data.

Let’s look at ROM’s relation API in more detail by moving on to [displaying tasks](/tutorials/rails/displaying-tasks).

