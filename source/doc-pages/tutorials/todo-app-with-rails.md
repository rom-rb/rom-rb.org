
This tutorial explains how to make ROM feel right at home in your Rails application. It is primarily intended for those familiar with Rails who want to learn more about ROM.

To understand how ROM integrates with Rails, we will work through the steps required to build a simple todo list application.

The application will have the following capabilities:

* [Getting started](/tutorials/rails/getting-started) - quickly initialize an application with a ROM-based template
* [Displaying tasks](/tutorials/rails/tasks-index) - understand ROM’s read model by displaying a list of tasks
* [Managing tasks](/tutorials/rails/task-relation) - 
* [Task mapper](/tutorials/rails/task-mapper) - define a dedicated mapper for domain objects
* [Managing tasks](/tutorials/rails/managing-tasks) - implement create/update/delete actions with commands
* [Validations](/tutorials/rails/validations) - use validators
- Displaying the list of tasks
- Filtering and ordering the list of tasks
- Creating new tasks
- Updating, re-prioritizing and completing tasks
- Deleting tasks

By the end of this tutorial, you’ll have learned the following:

- How ROM integrates with Rails
- How to use ROM to build basic CRUD applications
- How to test Rails apps that depend on ROM

If that sounds good, then let’s get started!

_Note: You'll need a newish version of Rails installed and available to make this all work._

## Getting Started

First, we need to create a new Rails application. To get up and running quickly
we've provided a small [application template](https://github.com/rom-rb/rom-rb.org/blob/master/source/tutorials/code/rom-todo-app-template.rb) which takes care of a few minor setup details.

Open up a terminal and create a new Rails application with the following commands:

``` shell
wget http://rom-rb.org/tutorials/code/rom-todo-app-template.rb
rails new rom-todo-app -JTS -m rom-todo-app-template.rb
```

Watch the logs fly by as your new Rails app is created.

### What’s happening here?

In addition to the normal Rails installation, the application template includes the following extra steps:

- Adding `rom`, `rom-sql`, and `rom-rails` dependencies to the `Gemfile`
- Replacing the Rails test defaults with `rspec` and `capybara`
- Adding `require 'rom-rails'` to `config/application.rb`
- Adding a `tasks` table to the database and running `db:migrate`
- Adding a `tasks` resource route
- Adding relation, mapper and command classes for `tasks` 

### Open the Rails console

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

To retrieve all the tasks in the todo list, we get the relation from the registry and call `to_a` on it. This executes the query and returns an array of results:

```ruby
rom.relation(:tasks).to_a
```

We should get back an empty array here, because the database is currently empty.

### Use a command to create a task

Create a new todo task by getting the create command from the registry and calling it with a hash of attributes to save:

```ruby
rom.command(:tasks).create.call(title: 'finish the tutorial')
```

The `create` command is called with a hash of attributes to be saved, and returns a result object representing the created task.

### Read back the task we just created

Look up the tasks relation again, and materialize it to an array:

```ruby
rom.relation(:tasks).to_a
```

Or get at the task directly:

```ruby
rom.relation(:tasks).first
```

Now that we’ve got the basic database and ROM integration up and running, let’s get the app working end-to-end by connecting the tasks relation to a controller and a view template.

## Filtering and Mapping

We’ll start by building an index page to display all the tasks in our todo list.

### An Index Action

To read data from the tasks relation that we set up previously, make a route to a new controller in `app/controllers/tasks_controller.rb`.

If you don’t want to do this manually, you can generate the controller with the following command:

```shell
bin/rails generate controller tasks
```

Hook in the tasks relation to the index action of the controller:

```ruby
# app/controllers/tasks_controller.rb

class TasksController < ApplicationController
  def index
    render locals: { tasks: rom.relation(:tasks) }
  end
end
```

To run this, start the Rails server with the following command:

```shell
bin/rails server
```

Sending a request to this action at `http://localhost:3000/tasks` will give us an error due to a missing template. So let’s fill that in now:

``` erb
# app/views/tasks/index.html.erb

<ul>
  <% tasks.each do |task| %>
    <li>
      <%= task[:title] %>
    </li>
  <% end %>
</ul>
```

And just like that, we’re listing tasks!

Notice that we’re using raw hash keys to access the task attributes in the template. This is because the relation doesn’t yet know how to map the list of tasks to a particular model.

Before addressing this, let’s first explore how to set up more granular queries on the relation.

As well as displaying the full list of tasks, the requirements of our app call for us to be able to filter the tasks by their status (active and completed) and order them by priority.

### Filtering with Relations

The specific capabilities of a relation depend on the dataset adapter it’s configured with. Here, we’re using [rom-sql](https://github.com/rom-rb/rom-sql), which gives us access to the [Sequel Dataset API](http://sequel.jeremyevans.net/rdoc/classes/Sequel/Dataset.html).

The tasks table generated by the application template has a boolean `done` column which represents the status of each task. To filter the list of tasks based on this status, add `by_active` and `by_completed` methods to the relation, like this:

```ruby
# app/relations/tasks.rb

class Tasks < ROM::Relation[:sql]
  dataset :tasks

  def by_active
    where(done: true)
  end

  def by_completed
    where(done: false)
  end
end
```

Note that in Sequel, `filter` can be used as an alias for `where`. Use whatever style you prefer.

To display these filtered lists, we’ll need to make changes to the controller and view.

### Queries from the controller

One approach we could take is a one-to-one mapping between the relation queries and controller actions. That would lead to something like the following:

```ruby
# app/controllers/tasks_controller.rb

class TasksController < ApplicationController
  def index
    render_with_index tasks: tasks
  end

  def active
    render_with_index tasks: tasks.by_active
  end

  def completed
    render_with_index tasks: tasks.by_completed
  end

  private

  def render_with_index(context)
    render :index, locals: context
  end

  def tasks
    rom.relation(:tasks)
  end
end
```

Or we could stick to the resource routing style, using a single action to delegate to the various filters.

```ruby
# app/controllers/tasks_controller.rb

class TasksController < ApplicationController
  def index
    render locals: { tasks: by_status(params[:status]) }
  end

  private

  def by_status(status)
  	if status == 'active'
  	  rom.relation(:tasks).active
  	elsif status == 'completed'
  	  rom.relation(:tasks).active
  	else
  	 rom.relation(:tasks)
  	end
  end
end
```

```ruby
# app/relations/tasks.rb

class Tasks < ROM::Relation[:sql]
  dataset :tasks

  def active
    where(done: true)
  end

  def active
    where(done: false)
  end
end
```

Should `by_status` be a private method on the controller, or extracted to the relation itself?

Our todo app here is little more than a toy, so it’s not going to make much difference either way, but in a larger app this decision might be more significant.

In this case, we’ve gone with the controller, because the `status` concept is currently part of the UI and our data model doesn’t know about it. But this distinction is fluid, and could be argued either way.

### Adding status navigation

In order to see these status filters, we need to be able to navigate between them from UI.

Add the following partial to the view path for tasks:

```erb
# app/views/tasks/_filter_nav.html.erb

<nav>
    <ul>
        <li><%= link_to 'All', tasks_path %></li>
        <li><%= link_to 'Active', tasks_path(status: :active) %></li>
        <li><%= link_to 'Completed', tasks_path(status: :completed) %></li>
    </ul>
</nav>

```

Then we need to render the partial from the index view. While we’re here, we should render the status for each task as well.

```erb
# app/views/tasks/_filter_nav.html.erb

<%= render 'filter_nav' %>

<ul>
  <% tasks.each do |task| %>
    <li>
      <span><%= task[:title] %></span>
      <span><%= status_label(task[:is_complete]) %></span>
    </li>
  <% end %>
</ul>
```

Rather than inline it in the ERB template, we’ll flip the `status_label` in a pure Ruby helper:

```ruby
# app/helpers/tasks_helper.rb

module TasksHelper
  def status_label(is_completed)
    if is_completed then 'Completed' else 'Active'; end
  end
end
```

If this extra view logic seems a little off to you, you’ve got the right idea.

Not only is the helper adding an extra layer of complication and indirection, it also introduces a subtle bit of duplicate logic. We’re now conditionally checking the value of `status` in two different places.

That’s a sign we’re missing a unifying concept, and in fact we are. In some situations hashes may be all you need, but more often than not, you'll want to represent your data with a proper domain object.

The **M** in ROM stands for **Mapper** and it is through a mapper that we'll transform our hashes into something a little more useful.

## Mapping to a model

To start, we'll need to define a model for the mapper to use. This can be
whatever kind of object you like—either a plain old Ruby object or something more sophisticated. The only required contract is that its constructor must accept the hash of attributes passed to it by the mapper.

Here we’ll use
[Virtus value objects](https://github.com/solnic/virtus/#value-objects)
to define the `Task` class because they come out-of-the-box with the required attribute hash construction, as well as various other useful features.

Create a new model class called `Task` in the `app/models` path, and mix in the value object behaviour:

``` ruby
# app/models/task.rb

# Isolate the Virtus API behind a domain-specific object
ValueObject = Virtus.value_object(coerce: false)

class Task
  include ValueObject

  values do
    attribute :id, Integer
    attribute :title, String
    attribute :is_completed, Boolean
  end
end
```

With a model class defined, we can simply instruct the task mapper to use it directly, providing the list of attributes we want to map:

``` ruby
# app/mappers/tasks.rb

class TaskMapper < ROM::Mapper
  relation :tasks

  model Task

  attribute :id
  attribute :title
  attribute :is_completed
end
```

By default, ROM does not implicitly trigger mappers on relations. Pass the name of the mapper to the `as` method on the relation to map hash results into models:

```ruby
# app/controllers/tasks_controller.rb

class TasksController < ApplicationController
  def index
    render locals: { tasks: by_status(params[:status]).as(:tasks) }
  end

  private

  def by_status(status)
    if status == 'active'
      tasks.by_active
    elsif status == 'completed'
      tasks.by_completed
    else
     tasks
    end
  end

  def tasks
	rom.relation(:tasks)
  end
end
```

This will work immediately, without requiring changes to the template, because Virtus supports access to attributes via the `[]` method.

But we don’t want the appearance of hash-like objects propagating through our app, so we’ll change it now.

With the mapping in place, we can blow away the ad-hoc helper by providing `status` and `status_label` methods directly on the model:

```ruby
# app/models/task.rb

# Isolate the Virtus API behind a domain-specific object
ValueObject = Virtus.value_object(coerce: false)

class Task
  include ValueObject

  values do
    attribute :id, Integer
    attribute :title, String
    attribute :is_completed, Boolean
  end

  def status
  	if is_completed
  	  :completed
  	else
      :active
  	end
  end

  def status_label
    status.to_s.capitalize
  end
end
```

Update the template to replace the hash-style lookups with model attributes:

```erb
# app/views/tasks/index.html.erb

<%= render 'filter_nav' %>

<ul>
  <% tasks.each do |task| %>
    <li>
      <span><%= task.title %></span>
      <span><%= task.status_label %></span>
    </li>
  <% end %>
</ul>
```

It now makes more sense to make `status` a fully fledged part of the domain model.

We can extract the logic for filtering by status to the relation, leaving the controller as lightweight as possible:

```ruby
# app/relations/tasks_relation.rb

class TasksRelation < ROM::Relation[:sql]
  dataset :tasks

  def by_status(status)
    if status == 'active'
      by_active
    elsif status == 'completed'
      by_completed
    else
     self
    end
  end

  def by_active
    where(is_completed: false)
  end

  def by_completed
    where(is_completed: true)
  end
end
```

```ruby
class TasksController < ApplicationController
  def index
    render locals: { tasks: tasks_by_status(params[:status]) }
  end

  private

  def tasks_by_status(status)
    rom.relation(:tasks).by_status(status).as(:tasks)
  end
end
```

## Forms and Validation

First, we’ll create base form for managing tasks.

Forms are constructed from `input` and `validation` blocks.

```ruby
# app/forms/task_form.rb

class TaskForm < ROM::Model::Form
  input do
    set_model_name 'Task'

    attribute :title, String
    attribute :is_completed, Boolean
  end

  validations do
    relation :tasks

    validates :title, presence: true
  end
end
```

We also need to add a new method to the relation to access individual tasks by their given ID:

```ruby
class Tasks < ROM::Relation[:sql]
  def by_id(id)
    where(id: id)
  end
end
```

```ruby
# app/forms/new_task_form.rb

class NewTaskForm < UserForm
  commands tasks: :create

  def commit!
    tasks.try { tasks.create.call(attributes) }
  end
end
```

```ruby
# app/forms/update_task_form.rb

class UpdateTaskForm < UserForm
  commands tasks: :update

  def commit!
    tasks.try { tasks.update.by_id(id).set(attributes) }
  end
end
```

```ruby
# app/controllers/tasks_controller.rb

class TasksController < ApplicationController

  def new
    render :new, locals: { user: NewTaskForm.build }
  end

  def create
    task_form = NewTaskForm.build(params[:task]).save

    if task_form.success?
      redirect_to :tasks
    else
      render :new, locals: { task: task_form }
    end
  end

  def edit
    task_form = UpdateTaskForm.build({}, { id: params[:id] })

    render :edit, locals: { task: task_form }
  end

  def update
    task_form = UpdateTaskForm.build(params[:user], id: params[:id]).save

    if task_form.success?
      redirect_to :tasks
    else
      render :edit, locals: { task: task_form }
    end
  end
```

