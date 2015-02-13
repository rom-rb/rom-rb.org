## Getting started

_Note: You'll need a newish version of Rails installed and available to make this
all work._

First, we need to create a new Rails application. To get up and running quickly
we've provided a small [application template](https://github.com/rom-rb/rom-rb.org/blob/master/source/tutorials/code/rom-todo-app-template.rb) which takes care of a few details.

Open up a console and create a new Rails application with the following command:

``` shell
rails new rom-todo-app -JTS -m http://rom-rb.org/tutorials/code/rom-todo-app-template.rb
```

Alternatively, download the template first, then reference it from a local file path:

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

### Autoload the ROM objects

The Rails template introduces a convention for managing objects provided by ROM alongside the familiar Rails conventions.

Commands, mappers, and relations are autoloaded and registered with the ROM environment when placed in the following locations:

- `app/commands`
- `app/mappers`
- `app/relations`

If you’ve been following along with the console, you’ll see that the Rails template generated a `tasks.rb` file in each of these paths as well as a `*_create_tasks.rb` migration in `db/migrations`.

Use the following methods to look up the registered task objects on the environment:

```ruby
rom.commands
rom.mappers
rom.relations
```

### Get the list of tasks

To get the list of tasks, we go through the reader API and call `to_a`, which executes the query and returns an array of results:

```ruby
rom.read(:tasks).to_a
```

We should get back an empty array because there are currently no tasks in the database.

### Use a command to create a task

Create a new task by looking up the command registry and executing a transaction:

```ruby
rom.command(:tasks).try do
  create(title: 'Finish the ROM Rails tutorial')
end
```

The `create` method accepts a hash of attributes to be saved, and returns a result object representing the created task.

### Read back the task we just created

Look up the tasks reader again, and materialize its relation:

```ruby
rom.read(:tasks).to_a
```

We haven’t yet defined a mapper or added any queries to the relation so all we can do at this point is read back the entire set of tasks as an array of hashes.

Readers and relations always return immutable collections supporting Ruby’s [Enumerable](http://ruby-doc.org/core-2.2.0/Enumerable.html) interface:

```ruby
rom.read(:tasks).first

rom.read(:tasks).count

rom.read(:tasks).each { |t| puts t[:title] }

rom.read(:tasks).map { |t| t[:id] }

rom.read(:tasks).detect { |t| t[:title].match(/ROM/) }
```

But with nothing more than an empty relation defined, there’s not a lot we can do in terms of querying this data.

Let’s look at ROM’s relation API in more detail by moving on to [building a tasks index](/tutorials/rails/tasks-index).

