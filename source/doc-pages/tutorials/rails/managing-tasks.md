## Managing tasks

In this section you will learn how to implement create & update actions in
tasks controller using ROM [commands](/introduction/commands). Along the way
we will extend relations and integrate our rom functionality more fully into
the application.

ROM strives to create clean separations for the different responsibilities of an
application. Commands allow us to create explicit ways to manipulate our
data.

Basic commands were automatically created for you when you generated the app
skeleton. You can find them in `app/commands`.

``` ruby
# app/commands/tasks.rb

ROM.commands(:tasks) do
  define(:create) do
    result :one
  end

  define(:update) do
    result :one
  end

  define(:delete) do
    result :one
  end
end
```

It may be disorienting to have data manipulation functionality like this
outside of the model if you come from a standard Rails application background.
Querying data and changing data are often mixed together in ORMs. Keep in mind
that ROM wants these things pulled apart. Let's see how our application looks
when we use these commands.

### Creating tasks

We will need a view and a controller action to take advantage of the create
command. As a reminder, the `create` command is implemented like this (from
above):

``` ruby
ROM.commands(:tasks) do
  define(:create) do
    result :one
  end

  # ...
end
```

#### Add the "new" scenario

Add a new scenario to the tasks feature spec for adding tasks:

``` ruby
# spec/features/tasks_spec.rb

require 'rails_helper'

feature 'Tasks' do
  # ...

  scenario 'I can add a new task' do
    visit new_task_path

    find('#task_title').set('Write tests')
    click_on 'Save'

    expect(page).to have_content('Tasks#index')
    expect(page).to have_content('Write tests')
  end
end
```

_No need to add the route since our application template added `resources
:tasks` to our routes.rb file._

#### Make it pass

##### Add the `new` template

``` erb
<%# app/views/tasks/new.html.erb %>

<%= form_for :task, url: tasks_path do |f| %>
  <%= f.text_field :title %>
  <%= f.submit 'Save' %>
<% end %>
```

##### Add the `create` action

``` ruby
# app/controllers/tasks_controller.rb

class TasksController < ApplicationController
  # ..

  def create
    # Rails 'strong parameters'
    attributes = params.require(:task).permit(:title)
    rom.command(:tasks).try { create(attributes) }

    redirect_to :tasks
  end
end
```

This is enough to make the test pass:

``` shell
$ bin/rspec spec/features/tasks_spec.rb
..

Finished in 0.13225 seconds (files took 0.33654 seconds to load)
2 examples, 0 failures
```

Now we have an interface for creating new tasks. It doesn't look all that
different from what we're used to outside of the usage of `rom.command`.

### Updating tasks

The command for updating looks like this:

``` ruby
ROM.commands(:tasks) do
  # ...

  define(:update) do
    result :one
  end

  # ...
end
```

To update tasks we'll need a view and controller action for `edit` along with
an action for `update`.

#### Add the "edit" scenario

``` ruby
# spec/features/tasks_spec.rb

feature 'Tasks' do
  # ...

  scenario 'I can edit a task' do
    visit tasks_path

    click_on 'Task One'

    find('#task_title').set('Updated Task One')
    click_on 'Save'

    expect(page).to have_content('Tasks#index')
    expect(page).to have_content('Updated Task One')
  end
end
```

#### Add the `edit` template

``` erb
<%# app/views/tasks/edit.html.erb %>

<%= form_for :task, url: task_path(id: task.id), method: :post do |f| %>
  <%= f.text_field :title %>
  <%= f.submit 'Save' %>
<% end %>
```

#### Add the `edit` action

``` ruby
class TasksController < ApplicationController
  # ...

  def edit
    task = rom.read(:tasks).by_id(params[:id]).first
    render :edit, locals: { task: task }
  end
end
```

Oops! We are trying to use the `#by_id` relation method above. We should probably
add it. If you remember, we can create new methods on a relation quite easily.
Let's take a short detour and take care of that.

#### Specify `by_id`

``` ruby
# spec/relations/tasks_spec.rb

describe 'Tasks relation' do
  # ...

  describe 'by_id' do
    it 'returns a task by id' do
      task = ROM.env.read(:tasks).by_id(1).first

      expect(task.title).to eq('Task One')
    end
  end
end
```

Currently ROM relations are all enumerable so we need to add `#first` to get
the single object.

#### Implement `by_id`

``` ruby
# app/relations/tasks.rb

ROM.relation(:tasks) do
  def by_id(id)
    where(id: id)
  end

  # ...
end
```

_Don't forget: `where(id: id)` is a method on the Sequel adapter._

Since we already added a mapper for tasks the result of this method is an
instance of the `Task` value object.

We're close but we need a way to update the task.

####  Add the `update` action

``` ruby
class TasksController < ApplicationController
  # ...

  def update
    # Rails 'strong parameters'
    attributes = params.require(:task).permit(:title)
    task_id = params[:id]

    rom.command(:tasks).try { update(:by_id, task_id).set(attributes) }

    redirect_to :tasks
  end
end
```

#### Small update to `index` view

And our scenario requires that task titles be links in the index view:

``` erb
# app/views/tasks/index.html.erb

<h1>Tasks#index</h1>

<ul>
  <% tasks.each do |task| %>
    <li>
      <%= link_to task.title, edit_task_path(id: task.id) %>
    </li>
  <% end %>
</ul>
```

#### Passing tests!

Just like that, our tests should pass:

``` shell
$ bin/rspec spec/features/tasks_spec.rb
...

Finished in 0.17617 seconds (files took 0.35988 seconds to load)
3 examples, 0 failures
```

#### What's next?

We don't have a way to delete tasks so our management is incomplete. It turns
out that the delete action is so trivial you should be able to do it on your
own. Start with that scenario and work inward toward the command.

Validations and error handling are sorely lacking in our implementation. That
seems like a good thing to cover [next](/tutorials/rails/validations).
