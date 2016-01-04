<aside class="well">
This tutorial is out of date. Please <a href="https://github.com/rom-rb/rom-rb.org/issues/70">let us know</a>
if you'd like to help with updating it.
</aside>

# Todo App With Rails

This tutorial explains how to make ROM feel right at home in your Rails application. It is primarily intended for those familiar with Rails who want to learn more about ROM.

To understand how ROM integrates with Rails, we will work through the steps required to build a simple todo list application.

The application will have the following capabilities:

- Displaying the list of tasks
- Filtering and ordering the list of tasks
- Creating, updating and deleting tasks

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

In a default Rails setup, the ROM environment is loaded from the standard [ActiveRecord  configuration](http://guides.rubyonrails.org/configuring.html#configuring-active-record). As long as the database specified there is supported by ROM SQL, no additional setup is necessary.

#### ActiveRecord-less cases

If ActiveRecord is not used, or there is no `database.yml` it's necessary to add an initializer.
Easiest and preferable way is using a Database URL.

```ruby
# config/initializers/rom.rb
ROM::Rails::Railtie.configure do |config|
  config.gateways[:default] = [:sql, ENV.fetch('DATABASE_URL')]
end
```

Example of URL - `sqlite://db/development.sqlite3` or `jdbc:sqlite://db/development.sqlite3` (in case of jRuby).

### Working with ROM objects

The Rails template introduces a convention for managing objects provided by ROM alongside the familiar Rails conventions.

Commands, mappers, and relations are autoloaded and registered with the ROM environment when placed in the following locations:

- `app/commands`
- `app/mappers`
- `app/relations`

If you look inside these paths in the Rails app, you’ll see that the application template generated a `tasks.rb` file in each of these paths as well as a `*_create_tasks.rb` migration in `db/migrations`.

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

## Relations and Mappers

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

The tasks table generated by the application template has a boolean `is_completed` column which represents the status of each task. To filter the list of tasks based on this status, add `active` and `completed` methods to the relation, like this:

```ruby
# app/relations/tasks_relation.rb

class TasksRelation < ROM::Relation[:sql]
  def active
    where(is_completed: false)
  end

  def completed
    where(is_completed: true)
  end
end
```

To display the lists from this relation, we’ll need to make changes to the controller and view.

### Queries from the controller

One approach we could take is a one-to-one mapping between the relation queries and controller actions.

That would lead to something like the following:

```ruby
# app/controllers/tasks_controller.rb

class TasksController < ApplicationController
  def index
    render_with_index tasks: tasks
  end

  def active
    render_with_index tasks: tasks.active
  end

  def completed
    render_with_index tasks: tasks.completed
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
    case status
    when 'active'
      tasks.active
    when 'completed'
      tasks.completed
    else
      tasks
    end
  end

  def tasks
    rom.relation(:tasks)
  end
end
```

Should `by_status` be a private method on the controller, or extracted to the relation itself? As always in software development, the best answer is “it depends”.

From the perspective of encapsulating data access, this behaviour does make more sense in the relation. A counter argument is that the `status` concept is part of the user interface and the data model shouldn’t need to know about it directly.

One way of clarifying this is to reconsider the role of the relation in the controller. Rather than just exposing the query scopes directly, we could use it to expose a specific view into the encapsulated dataset, an approach which becomes more clear if we rename `by_status` to `index_view`:

```ruby
# app/relations/tasks_relation.rb

class TasksRelation < ROM::Relation[:sql]
  def index_view(status)
    case status
    when 'active'
      active
    when 'completed'
      completed
    else
      self
    end
  end

  def active
    where(is_completed: false)
  end

  def completed
    where(is_completed: true)
  end
end
```

If you prefer the more explicit style of calling query methods with prepositional phrases, you can keep `by_status` as the name of the method here.

Our app here is little more than a toy, so it’s not going to make much difference whether you put this logic in the relation or controller. But in a larger app, the approach you choose could have a significant effect on the resulting code, so it’s worth thinking carefully about.

### Adding status navigation

Let’s start wiring this thing together. In order to see items filtered by active and completed status, we need to be able to navigate between them from UI.

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

Now we can render this partial from the index view. While we’re here, we can also render the status for each task as well.

```erb
# app/views/tasks/index.html.erb

<%= render 'filter_nav' %>

<ul>
  <% tasks.each do |task| %>
    <li>
      <span><%= task[:title] %></span>
      <span><%= status_label(task[:is_completed]) %></span>
    </li>
  <% end %>
</ul>
```

Rather than inlining logic in the ERB template, we’ll flip the `status_label` with a pure Ruby helper:

```ruby
# app/helpers/tasks_helper.rb

module TasksHelper
  def status_label(is_completed)
    if is_completed then 'Completed' else 'Active'; end
  end
end
```

If this extra view complexity seems a little off to you, you’ve got the right idea.

Not only is the helper adding an extra layer of indirection, it also introduces a subtle bit of duplicate logic. We’re now conditionally checking the value of `status` in two different places.

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

With our value object defined, we can simply instruct the task mapper to use it directly, providing the model class:

``` ruby
# app/mappers/task_mapper.rb

class TaskMapper < ROM::Mapper
  relation :tasks

  model Task
end
```

By default, ROM does not implicitly trigger mappers on relations. Pass the name of the mapper to the `as` method on the relation to map hash results into models:

```ruby
# app/controllers/tasks_controller.rb

class TasksController < ApplicationController
  def index
    render locals: {
      tasks: tasks.index_view(params[:status]).as(:tasks)
    }
  end

  private

  def tasks
    rom.relation(:tasks)
  end
end
```

This will work immediately, without requiring changes to the template because Virtus supports access to attributes via the `[]` method.

But we don’t want the appearance of hash-like objects propagating through our app, so we’ll change it now.

With the object mapping in place, we can blow away the ad-hoc helper by providing `status` and `status_label` methods directly on the model:

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

At this point, we have a much cleaner controller, the `status` concept is a fully formed part of our model, and the relation provides a cohesive API that encapsulates the dataset.

### Making Sense of Relations and Mappers

In just a few lines of code, we’ve encountered a number of differences between the ROM Rails and an “omakase” Rails app with ActiveRecord:

- Plural relations and singular models are separate classes
- The model is a [value object](http://www.c2.com/cgi/wiki?ValueObject)
- The relation and model are read-only
- Mapping the dataset to the model is an explicit step

These differences reflect the core philosophy of ROM. Each layer of an application should only have access to the data and behaviour it requires and no more. There’s no reason to plug a larger set of ORM features into a context where they’re not required.

Despite being in contrast to the Rails style of a [maximalist interface](http://martinfowler.com/bliki/HumaneInterface.html), the more restrictive approach is equally expressive and understandable at a glance. We know what data is being passed to the view and we have attributes on the model reflecting the principle of least astonishment (`task.title` just works).

For now, that’s all you need to know about relations and mappers.

_It’s worth noting that many of the explicit steps and manual wiring demonstrated here can be automatically configured when the ROM objects are registered. In the interim, we’re focusing on the lower level building blocks of our APIs and ensuring that we have a solid foundation in place for these higher levels of abstraction in future._

## Forms and Validation

Instead of mixing together the parts of an application that query data and the parts that change data, ROM’s API splits these out into separate responsibilities.

This might be disorienting at first if you’re used to ActiveRecord. Once you grok [CQRS](http://martinfowler.com/bliki/CQRS.html), the concept makes a whole lot more sense.

### A Higher Level of Abstraction

In [Getting Started](#getting-started), you saw how to use a command to create a task in the Rails console:

```ruby
rom.command(:tasks).create.call(title: 'finish the tutorial')
```

Here’s how this command is registered and set up behind the scenes:

```ruby
# app/commands/task_commands/create.rb

module TaskCommands
  class Create < ROM::Commands::Create[:sql]
    relation :tasks
    register_as :create
    result :one

    # define a validator to use
    # validator TaskValidator
  end
end
```

By convention, the command class is wrapped in a module namespace. If you want to create a new command, you can do it manually in `app/commands` or use the provided generator:

```
rails generate rom:commands tasks --adapter sql
```

Commands are the basic method by which ROM sends write commands to a data source. Commands come into their own when there are complex data integrity rules and error handling at play.

But in the context of Rails, we’re not always dealing with rich and complex write logic. Famously, Rails is all about the CRUD. ROM goes with this flow by providing `ROM::Model::Form` utility for handling input mapping and validation.

Forms are a higher level abstraction built on top of commands to help simplify the boilerplate process of creating administration and CRUD apps.

### A Base Form for Managing Tasks

Forms are constructed by inheriting from `ROM::Model::Form` and declaring `input` and `validation` blocks.

There will be a lot of behaviour shared between the `create` and `update` forms, so we’ll create a base class that generalizes this:

```ruby
# app/forms/task_form.rb

class TaskForm < ROM::Model::Form
  input do
    set_model_name 'Task'

    attribute :title, String
    attribute :is_completed, Virtus::Attribute::Boolean
  end

  validations do
    relation :tasks

    validates :title, presence: true
  end
end
```

Notice that we also need to slot in references to the model and relation here, in order to connect this form to our existing ROM objects.

In order to select and operate on individual objects, we also need to add a couple methods that access tasks by their ID:

```ruby
# app/relations/tasks_relation.rb

class TasksRelation < ROM::Relation[:sql]
  def by_id(id)
    where(id: id)
  end

  # ...
end
```

### Creating a New Task

Now that the base `TaskForm` is set up, we can inherit from it to build specialized forms for each write operation.

The form to create a new task requires a mapping to the `create` command and a `commit!` method which executes this command on the attributes passed through from the input parameters.

```ruby
# app/forms/new_task_form.rb

class NewTaskForm < TaskForm
  commands tasks: :create

  def commit!
    tasks.try { tasks.create.call(attributes) }
  end
end
```

If you don’t want to wrangle all this manually, you can also use the provided Rails generator:

```
rails generate rom:form tasks --command create
```

Creating a view template for this form is easily done with the built-in Rails tag helpers:

```erb
# app/views/tasks/new.html.erb

<%= form_for task do |t| %>
  <%= task.errors.full_messages if task.errors.present? %>
  <%= t.text_field :title %>
  <%= t.select :is_completed, [['Completed', true], ['Active', false]] %>
  <%= t.submit %>
<% end %>
```

The form for handling updates looks very similar to the form for creating new tasks.  In this case, we just need to add a class method to load existing records into the form. Also note that the methods defined here use the finder methods we defined on the `Tasks` relation earlier.

```ruby
# app/forms/update_task_form.rb

class UpdateTaskForm < TaskForm
  commands tasks: :update

  def self.build_from_existing(id)
    task = rom.relation(:tasks).by_id(id).one!
    self.build(task)
  end

  def commit!
    tasks.try { tasks.update.by_id(id).call(attributes) }
  end
end
```

To set up the edit functionality according to Rails conventions, we’ll need an `edit.html.erb` template as well.

### Managing Tasks from the Controller

Now that we have the components in place to handle creating and updating tasks, we can put these forms to use in the controller, mapping form commands to the `create` and `update` actions and template views to the `new` and `edit` actions:

```ruby
# app/controllers/tasks_controller.rb

class TasksController < ApplicationController
  # ...

  def new
    render :new, locals: { task: NewTaskForm.build }
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
    task_form = UpdateTaskForm.build_from_existing(params[:id])

    render :edit, locals: { task: task_form }
  end

  def update
    task_form = UpdateTaskForm.build(params[:task], id: params[:id]).save

    if task_form.success?
      redirect_to :tasks
    else
      render :edit, locals: { task: task_form }
    end
  end
```

Use the `form.success?` method to check the result of the form commands. When it returns false, we return to the template where we came from and let the form object provide its list of validation errors, based on rules declared in the form’s `validations` block.

### Don’t Forget to Delete Tasks

Deletion of individual tasks can be handled in a similar way to creating and updating, except that you don’t need to set up a form or template.

```ruby
class TasksController < ApplicationController
  # ...

  def delete
    tasks_command.try do
      tasks_command.delete.by_id(params[:id])
    end
  end

  private

  def tasks_command
    rom.command(:tasks)
  end

end
```

__Error handling in the Rails controller context, along with an explanation of how to use commands directly in actions would be extremely helpful for people to take this example and run with it (for more than just deletes). Also, a clarification of how `try` works is needed.__

### Separating Write Commands

The sharp division of responsibility between relations and commands comes into its own for apps that use multiple data sources or a database cluster with primary and replica nodes.

Even in a smaller, contained context where both relations and commands are pointing to the same data source, there are various design benefits that emerge when commands and queries are kept separate:

- No need for concepts like “presenters” or “view models”. Mappers can transform the same data into different value objects, regardless of what the primary model looks like.
- Validation and transactional error handling is easier to treat as a first-class concern when it’s not coupled to the parts of the app that don’t need it.
- Avoiding the complexity of associations in an ORM model. Precision modelling of relationships between entities is less significant when there’s no need to traverse the same object graph in both read and write contexts.

Oftentimes, Rails developers end up building apps that are larger and more complex than the defaults of Rails are set up to support. With Rails, ROM aims to fulfil this specific need.

## Testing ROM with Rails

Testing ROM with Rails is fairly straightforward.

### Testing Relations

You can run full integration tests on relations in the same way that you’d test any other data access object:

```ruby
# spec/relations/tasks_spec.rb

require 'rails_helper'

describe 'Tasks relation' do
  fixtures :tasks

  describe '#by_status' do
    let(:tasks_relation) { ROM.env.read(:tasks) }

    it 'filters tasks by completed' do
      tasks = tasks_relation.by_status(:completed)

      expect(tasks.to_a).to eql(
        [{:id=>1, :title=>"start the tutorial"}]
      )
    end

    it 'filters tasks by active' do
      tasks = tasks_relation.by_status(:active)

      expect(tasks.to_a).to eql(
        [{:id=>2, :title=>"finish the tutorial"}]
      )
    end
  end
end
```

## Migrations

ROM doesn’t yet have a native concept of schema migrations.

### ActiveRecord

One approach is to use the Rails defaults for ActiveRecord migrations as you normally would, and just replace the use of ActiveRecord models in your app with ROM components.

### Sequel

Alternatively you can use Sequel's
[Migration API](http://sequel.jeremyevans.net/rdoc/files/doc/migration_rdoc.html).

``` ruby
setup.sqlite.connection.create_table(:users) do
  primary_key :id
  String :name
  Boolean :admin
end

setup.sqlite.connection.create_table(:tasks) do
  primary_key :id
  Integer :user_id
  String :title
  Integer :priority
end
```

## Summary

In this tutorial we’ve taken a walk through a simple integration of ROM concepts into a very basic Rails application.

- We got up and running quickly with an application template and a brief discussion of the ROM-rails integration.
- Next we displayed a list of tasks on the index page of our new application. This showed us the basics of a ROM relation.
- A simple list of tasks wasn’t enough so we explored extending the tasks relation to give us a sorted list of tasks and use it in our views.
- Still not satisfied we realized that our array of hashes returned from relations didn’t cut it. We set up a task mapper and a value object to give us a richer representation of data.
- All of that would be great if we needed a read-only application. Managing tasks was next for us and there we learned about ROM commands and ROM command/query separation.
- Taking the command/query separation a little further helped us understand the ROM way of handling validations and errors.

We hope that what we’ve presented here helps you to better understand how ROM can be used in your Rails applications and beyond.

As always, you can fork the website, and help others by making this tutorial better.
