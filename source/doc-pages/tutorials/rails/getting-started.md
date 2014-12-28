## Getting started

We need to create a new Rails application. To get up and running quickly
we've provided a small application template which takes care of a few details.
_You'll need a newish version of Rails installed and available to make this
all work._

Create the new application by running the following command:

``` shell
rails new rom-todo-app -JTS -m https://gist.githubusercontent.com/solnic/adb4de6baaa5b27d9502/raw/a98bec94a754173378f4129900ca5affa17c427b/gistfile1.rb
```

This likely take a little while to run. While you're waiting you can read about
what the template is doing for us. It:

* Adds required gems to Gemfile
* Generates a migration that creates `tasks` table
* Generates `app/relations` with tasks relation
* Generates `app/mappers` with default definition for `tasks`
* Generates `app/commands` with default set of create/update/delete commands for
  `tasks`
* Creates `spec/fixtures` with basic test data for our specs

Once the `rails new` command and the template have completed you can change to
the app directory and open a Rails console:

``` shell
cd rom-todo-app
bin/rails c
```

Hooray! It worked! This is progress.

Now let's use ROM to create a new task. In the Rails console:
_(You don't have to type in the comments, they're just for us.)_

```ruby
# access the ROM environment
rom = ROM.env

# use a command to create a task
rom.command(:tasks).try { create(title: 'Try out ROM') }
=> #<ROM::Result::Success:0x007fb148755d90 @value={:id=>1, :title=>"Try out ROM"}>

# use the tasks relation to access the task we just created
rom.read(:tasks).to_a
=> [{:id=>1, :title=>"Try out ROM"}]
```

In this short bit of code we've already used three bits of ROM:

**Environment**
The first thing we did was access something called `ROM.env`. This environment
is a convention built specifically for frameworks like Rails where you need
global access to the ROM registry.

**Commands**
We'll cover these in more detail, but [commands](/introduction/commands) are
the way we create or modify data in our relations.

**Relations**
[Relations](/introduction/relations) provide a way to access our data. We're
just reading all the data from `tasks` and converting it into an array. We
haven't defined any [mappers](/introduction/mappers) yet so our read simply
returns hashes. We'll get to mappers soon enough though, don't you worry.
