# ROM Sinatra Tutorial

In this tutorial, we’ll walk through the steps required to build a web API for managing a todo list. Each example builds on the last, showing how ROM and Sinatra can work together to provide an effective toolkit for rapid prototyping microservices and REST APIs. 

For simplicity and clarity, this tutorial uses ROM’s setup DSL, though in larger apps, we recommend configuring ROM with explicit class definitions. This is analogous to the difference between Sinatra’s routing DSL and its modular application style.

If you’re looking for a more robust and intricate example of ROM integrated with a modular Sinatra application, see the [rom-sinatra sample app](https://github.com/gotar/sinatra-rom).

## Setup

Create a new app directory, add a `Gemfile` with the following dependencies, and run `bundle` to install them:

```ruby
source 'https://rubygems.org'

gem 'sinatra'
gem 'sinatra-contrib'
gem 'rom-sql'
```

Then create a basic hello world app in `todo_api.rb`:

```ruby
require 'sinatra'
require 'sinatra/json'
require 'rom-sql'

get '/tasks' do
  json todo: 'Finish the ROM Sinatra tutorial'
end
```

You can run this app from the Ruby interpreter directly with the following command:

```
ruby todo_api.rb
```

Or provide a `config.ru` like the following, which can be used with `rackup`:

```ruby
require './todo_api'
run Sinatra::Application
```

If you want to run the app with a tool like `foreman`, you’ll need a `Procfile`:

```
web: bundle exec rackup -p $PORT
```

With all the housekeeping and boilerplate out of the way, we can start looking at the todo API itself.

## Setup the tasks model

To load ROM into this app, we need to set up the SQL adapter and provide a connection string. Do this at the top of the Sinatra app file:

```ruby
setup = ROM.setup(:sql, 'sqlite::memory')
```

This gives us an object we can use to configure a tasks relation and mapper.

For starters, we’ll provide a way of finding tasks by `id`, using the [where method](http://sequel.jeremyevans.net/rdoc/classes/Sequel/Dataset.html#method-i-where) of the underlying Dataset:

```ruby
setup.relation(:tasks).do
  def by_id(id)
    where(id: id)
  end
end
```

With this relation in place, we can set up a mapper to convert these tasks into plain Ruby objects:

```ruby
setup.mapper(:tasks) do
  relation :tasks
  model name: 'Task'
  attribute :id
  attribute :title
  attribute :priority
  attribute :is_complete
end
```

Next, we’ll define a little helper method to look up the ROM environment from inside the routes:

```ruby
def rom
  ROM.env
end
```

## Implementing the read API

The primary resource in the API is `/tasks`. Rather than use the standard nested URL pattern that many CRUD-oriented frameworks use, we’ll separate actions on the resource into singular and plural URIs. This will better emphasise ROM’s concept of command/query separation. You’ll see why soon.

Now we have the ROM environment set up, we can add real data to the `GET` methods. Use `rom.read(:tasks)` to access the tasks relation and return enumerable query results to the JSON encoder:

```ruby
get '/tasks' do
  json rom.relation(:tasks).all
end

get '/task/:id' do
  json rom.relation(:tasks).by_id(params[:id]).first
end
```

Did you spot the problem here?

In the case of the collection query, the empty enumerable will encode to an empty JSON type which is probably what consumers of the API will expect.

But what happens when finding tasks `by_id` returns `nil`? This is a classic example of code that assumes the ‘happy path’.

We probably want to return a `404` when the given ID doesn’t match any tasks, so let’s amend the code to do that using Sinatra’s `halt`:

```ruby
get '/task/:id' do
  task = rom.relation(:tasks).by_id(params[:id]).first
  halt 404 if task.nil?
  json task
end
```

With more lines in the method, the chained query is starting to look a little verbose. Let’s change the `rom` helper function we made earlier to return the `:tasks` reader directly, rather than the entire ROM environment:

```ruby
def tasks
  ROM.env.relation(:tasks)
end
```

Now we can refactor the routes to use this new helper:

```ruby
get '/tasks' do
  json tasks.all
end

get '/task/:id' do
  task = tasks.by_id(params[:id]).first
  halt 404 if task.nil?
  json task
end
```

This is a good start, but we can make a much better API for listing tasks by adding more fine grained queries to the relation:

```ruby
setup.relation(:tasks).do
  def by_id(id)
    where(id: id)
  end
  
  def incomplete
    where(is_complete: false)
  end
  
  def complete
    where(is_complete: true)
  end
  
  def urgent
    incomplete.where(priority: 1)
  end
  
  def backlog
    incomplete.where { :priority > 1 }
  end
end
```

This provides us with the queries we need to add clean and intuitive views on the relation as part of the `/tasks` resource:

```ruby
get '/tasks'
  json tasks.all
end

get '/tasks/complete' do
  json tasks.complete
end

get '/tasks/incomplete' do
  json tasks.incomplete
end

get '/tasks/urgent' do
  json tasks.urgent
end

get '/tasks/backlog' do
  json tasks.backlog
end
```

Sinatra is very good for quickly sketching out APIs like this, but there is a lot of repetition in what we’ve done here.

Of course, there’s always [more than one way to do it](http://www.bignerdranch.com/blog/writing-readable-ruby/). The following example demonstrates how the separate routes defined above could be condensed into a single regex match:

```ruby
get %r{/tasks/(incomplete|complete|urgent|backlog)} do
  filter = params[:captures].first
  json tasks.send(filter.to_sym)
end
```

Or we could make the filter concept explicit in the resource and parameterize the relations rather than treat them as resources themselves:

```
get '/tasks/filter' do

end
```



## Relations are enumerable and immutable

In `rom-sql`, relations are proxies to [Sequel Dataset](http://sequel.jeremyevans.net/rdoc/files/doc/dataset_basics_rdoc.html) objects which ROM uses implicitly to build SQL statements, execute queries and return results from the underlying data store.

The Sequel documentation has a good description of what the Dataset does:

> A Dataset can be thought of representing one of two concepts:
> - An SQL query
> - An abstract set of rows and some related behavior

Relations always return enumerable objects. Chaining query methods together to restrict the results returns a new relation, rather than a modified copy of the original relation. Adhering to these principles allows ROM and Sequel to work together seamlessly and makes interactions between high level and low level code easier to reason about.

