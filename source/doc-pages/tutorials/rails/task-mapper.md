### Setting up Task mapper

ROM splits data access into two parts: relations and mappers. Inside relations
we define how we fetch the data. Mappers define how the data is presented to
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
