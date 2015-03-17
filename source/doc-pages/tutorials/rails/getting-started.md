After reading this, you’ll know how to integrate ROM with Rails

_Note: You'll need a newish version of Rails installed and available to make this
all work._

### Creating the application

First, we need to create a new Rails application. To get up and running quickly
we've provided a small [application template](https://github.com/rom-rb/rom-rb.org/blob/master/source/tutorials/code/rom-todo-app-template.rb) which takes care of a few minor setup details.

Open up a terminal and create a new Rails application with the following commands:

``` shell
wget http://rom-rb.org/tutorials/code/rom-todo-app-template.rb
rails new rom-todo-app -JTS -m rom-todo-app-template.rb
```

Watch the logs fly by as your new Rails app is created.

In addition to the normal Rails installation, the application template includes the following extra steps:

- Adding `rom`, `rom-sql`, and `rom-rails` dependencies to the `Gemfile`
- Replacing the Rails test defaults with `rspec` and `capybara`
- Adding `require 'rom-rails'` to `config/application.rb`
- Adding a `tasks` table to the database and running `db:migrate`
- Adding a `tasks` resource route
- Adding relation, mapper and command classes for `tasks` 

Once this is finished, change to the new application directory and open a Rails console:

```shell
cd rom-todo-app
bin/rails console
```

Hooray! You’ve now got a working Rails app with an integration to ROM.

Before diving into the structure of the app itself, let’s start by exploring the different parts of the ROM API from within the Rails console.

### Access the ROM environment

The ROM environment is provided specifically for frameworks like Rails where you need global access to the configured object graph.

To access the environment, type the following line into the Rails console:

```ruby
rom = ROM.env
```

By default, the ROM environment is configured with an SQLite repository and the registry of relations, mappers and commands.

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

We should get back an empty array here, because the database is currently empty.

### Use a command to create a task

Create a new task by getting the create command from the registry and calling it with a hash of attributes to save:

```ruby
rom.command(:tasks).create.call(text: 'finish the tutorial', priority: 1)
```

The `create` method accepts a hash of attributes to be saved, and returns a result object representing the created task.

### Read back the task we just created

Look up the tasks relation again, and materialize it to an array:

```ruby
rom.relation(:tasks).to_a
```

Or get at the task directly:

```ruby
rom.relation(:tasks).first
```

With nothing more than an empty `TasksRelation` class defined, all we can do at this point is read back the list of tasks as hashes.

### Next Steps

Let’s look at ROM’s read capabilities in more detail by moving on to [part 2 of this tutorial](/tutorials/rails/relations-and-mappers) where we explore relations and mappers.
