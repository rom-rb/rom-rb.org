### Setup

To use ROM with rails simply add `rom-rails` to your Gemfile:

``` ruby
gem 'rom-rails'
```

Make sure to use the latest version

## Schema

Defining schema is only required for adapters that don't support inferring schema
automatically. This means if you're using `rom-sql` you don't have to define the schema.
In other cases the railtie expects the schema to be in `db/rom/schema.rb` which
is loaded before relations and mappers.

## Relations, mappers and commands

The railtie automatically loads relations, mappers and commands from
`app/relations`, `app/mappers` and `app/commands` and finalizes the environment
afterwards. During the booting process the DSL is available through `ROM`.

## Sample TODO application

Here's a quick-start guide showing how you can build a simple todo app. Let's
generate a skeleton of the app using rom-rails template:

``` shell
rails new rom-todo-app -JTS -m http://rom-rb.org/doc-examples/rails-template.rb
```

The template created a couple of things for us:

* migrations that create `users` and `tasks` tables
* `app/relations` with users and tasks relations
* `app/mappers` with default definitions for `users` and `tasks`
* `app/commands` with default set of create/update/delete commands for `users`
  and `tasks`
* `spec/fixtures` with basic test data for our specs

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

Our mappers don't define any "object mapping" yet so ROM simply returns hashes.

For the sake of simplicity of this tutorial we're going to build a functionality
that will allow us to create, update and delete tasks. We assume that there's
always just one user exposed as `current_user` in the controllers.

### Displaying tasks

Let's write our first test describing how task index page should work:

``` ruby
# spec/features/tasks_spec.rb

require 'rails_helper'

feature 'Tasks' do
  fixtures :all

  scenario 'I can see a list of my tasks' do
    visit '/tasks/index'

    expect(page).to have_content('Task One')
  end
end
```

Now let's make it pass. First we will generate tasks controller with an index
action:

``` shell
bin/rails g controller tasks index
```

Here's the simplest implementation of `TasksController#index`:

``` ruby
class TasksController < ApplicationController
  def index
    render locals: { tasks: rom.read(:tasks) }
  end
end
```

And here's an erb template for the index action:

``` erb
<h1>Tasks#index</h1>

<ul>
  <%= tasks.each do |task| %>
    <li>
      <%= task[:name] %>
    </li>
  <% end %>
</ul>
```

Let's run our spec:

``` shell
$ bin/rspec spec/features/tasks_spec.rb
.

Finished in 0.04707 seconds (files took 1.31 seconds to load)
1 example, 0 failures
```

OK we're making progress. Let's fine-tune our index page and configure task
mapper so that we can have convenient data-access objects in our views rather
than plain hashes.

### Setting up Task mapper

ROM splits data access into two parts: relations and mappers. Inside relations
we define how we fetch the data. Mappers define how the data is represented to
our application layer.

We're going to start by specifying how task objects should look like:

``` ruby
# spec/relations/task_spec.rb

describe 'Task relation' do
  fixtures :tasks

  describe 'index_view' do
    let(:task_one) { Task.new(title: 'Task One') }
    let(:task_two) { Task.new(title: 'Task Two') }

    it 'returns task objects sorted by name' do
      tasks = ROM.env.read(:tasks).index_view

      expect(tasks.to_a).to eql([task_one, task_two])
    end
  end
end
```

This test fails telling us there's no relation called :index_view defined within
the tasks relation:

``` shell
$ bin/rspec spec/relations/tasks_spec.rb
F

Failures:

  1) Task relation index_view returns task objects sorted by name
     Failure/Error: tasks = ROM.env.read(:tasks).index_view
     ROM::NoRelationError:
       undefined relation :index_view within "tasks"
       # backtrace...

Finished in 0.00663 seconds (files took 0.2345 seconds to load)
1 example, 1 failure

Failed examples:

rspec ./spec/relations/tasks_spec.rb:10 # Task relation index_view returns task objects sorted by name
```

Let's define our missing relation:

``` ruby
# app/relations/tasks.rb
ROM.relation(:tasks) do
  def index_view
    select(:title).order(:title)
  end
end
```

We also would like to use our own domain objects, let's define them as Virtus
value objects:

``` ruby
# app/entities/task.rb

class Task
  include Virtus.value_object(coerce: false)

  values do
    attribute :title, String
  end
end
```

With an entity class defined we can simply instruct the task mapper to use it:

``` ruby
# app/mappers/tasks.rb
ROM.mappers do
  define(:tasks)

  define(:index_view, parent: :tasks, inherit_header: false) do
    model Task
    attribute :name
  end
end
```

You can use whatever object you like. Be it a plain PORO or something more
sophisticated. The only contract is that it must accept attribute hash in the
constructor.

We're using virtus value objects because they give us nice features out-of-the-box
like equality methods.

Now our test will pass:

``` ruby
$ bin/rspec spec/relations/tasks_spec.rb
.

Finished in 0.00746 seconds (files took 0.22541 seconds to load)
1 example, 0 failures
```

### Using dedicated task relation for index view

Now that we defined relation and mapping for the index view we can update the
controller and index erb template to use them:

``` ruby
# app/controllers/tasks_controller.rb
class TasksController < ApplicationController
  def index
    render locals: { tasks: rom.read(:tasks).index_view }
  end
end
```

and the view:

``` erb
<h1>Tasks#index</h1>

<ul>
  <%= tasks.each do |task| %>
    <li>
      <%= task.name %>
    </li>
  <% end %>
</ul>
```

### Summing up

Let's sum up what we've done so far:

* We defined a dedicated relation for "tasks index" view
* We defined a mapping for our "tasks index"
* We introduced `Task` entity to ease data access in the views

This is obviously quite a lot of work to build a simple feature, however its
purpose is to explain individual pieces of ROM and the philosophy behind it.

First of all we don't access query interface in the controller - we simply refer
to the relation that *we defined*. Secondly to display a list of tasks we use
a simple value object that exposes the required information - in our case it's
just the title attribute. Nothing else, nothing more. Consider this:

* We don't use an object that can be validated, because we don't need it
* We don't use an object that can be peristed, because we don't need it
* We don't have an object that can be changed, because we don't need it
* We don't have an object that exposes database query DSL, because we don't need it
* We don't have an object that can serialize itself, because we don't need it

In the next part we will see how to change the data and deal with params and
validations.
