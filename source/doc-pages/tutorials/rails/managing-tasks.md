## Managing tasks

In this section you will learn how to implement create & update actions in
tasks controller using ROM commands. When you generated the app skeleton basic
commands were automatically created for you. You can find them in `app/commands`.

### Creating tasks

Let's add a new scenario to our tasks feature spec:

``` ruby
require 'rails_helper'

feature 'Tasks' do
  fixtures :all

  scenario 'I can add a new task' do
    visit new_task_path

    find('#task_title').set('Write tests')
    click_on 'Save'

    expect(page).to have_content('Tasks#index')
    expect(page).to have_content('Write tests')
  end
end
```

OK time to make it pass:

``` ruby
# app/controllers/tasks_controller.rb
class TasksController < ApplicationController

  def create
    attributes = params.require(:task).permit(:title)

    result = rom.command(:tasks).try { create(attributes) }

    redirect_to :tasks
  end

end
```

And ERB template for the new action:

``` erb
# app/views/tasks/new.html.erb
<%= form_for :task, url: tasks_path do |f| %>
  <%= f.text_field :title %>
  <%= f.submit 'Save' %>
<% end %>
```

This is enough to make the test pass:

```
$ bin/rspec spec/features/tasks_spec.rb
..

Finished in 0.13225 seconds (files took 0.33654 seconds to load)
2 examples, 0 failures
```

### Updating tasks

We can easily implement edit/update actions in the similar fashion now:

``` ruby
# spec/features/tasks_spec.rb

feature 'Tasks' do
  fixtures :all

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

Our edit and update actions will need to find a task by its id so let's extend
the relation first:

``` ruby
# app/relations/tasks.rb
ROM.relation(:tasks) do
  def by_id(id)
    where(id: id)
  end

  def index_view
    select(:id, :title).order(:title)
  end
end
```

Now we can implement actions in the controller and add the views:

``` ruby
class TasksController < ApplicationController

  # ...

  def edit
    task = rom.read(:tasks).by_id(params[:id]).first
    render :edit, locals: { task: task }
  end

  def update
    attributes = params.require(:task).permit(:title)
    user_id = params[:id]

    rom.command(:tasks).try { update(:by_id, user_id).set(attributes) }

    redirect_to :tasks
  end
end
```

ERB template for edit action can look like that:

``` erb
# app/views/tasks/edit.html.erb
<%= form_for :task, url: task_path(id: task.id), method: :put do |f| %>
  <%= f.text_field :title %>
  <%= f.submit 'Save' %>
<% end %>
```

We also need to turn task titles into links in the index view:

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

Now our tests should pass:

```
$ bin/rspec spec/features/tasks_spec.rb
...

Finished in 0.17617 seconds (files took 0.35988 seconds to load)
3 examples, 0 failures
```

Delete action is so trivial that we're going to skip it and let you figure out
how to do it.

As you can see the implementation is simplified as it lacks validations and
error handling which is added in the [next section](/tutorials/rails/validations).
