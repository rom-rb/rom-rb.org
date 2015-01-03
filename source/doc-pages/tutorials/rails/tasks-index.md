## Displaying tasks

We know from [getting started](/tutorials/rails/getting-started) that we
can add tasks and read them out. It turns out that displaying tasks provides
a nice way to begin to see ROM and Rails working together.

Let's write a test to describe how the task index page should work. We
want a page that lists tasks, right?

``` ruby
# spec/features/tasks_spec.rb

require 'rails_helper'

feature 'Tasks' do
  fixtures :all

  scenario 'I can see a list of my tasks' do
    visit tasks_path

    expect(page).to have_content('Task One')
  end
end
```

If you run that, it should fail. That's what we want. Now let's make it
pass.

First we will generate tasks controller:

``` shell
# for some reason we need to stop spring before proceeding
bin/spring stop
bin/rails g controller tasks
```

Now, implement the `index` action. Here's the simplest one we can use:

``` ruby
# app/controllers/tasks_controller.rb

class TasksController < ApplicationController
  def index
    render locals: { tasks: rom.read(:tasks) }
  end
end
```

You'll probably recognize our `#read` method on the rom environment. We can
read all the tasks from the `tasks` relation and hand them off to the view.

And lastly, you'll need an erb template for the index action:

``` erb
# app/views/tasks/index.html.erb

<h1>Tasks#index</h1>

<ul>
  <% tasks.each do |task| %>
    <li>
      <%= task[:title] %>
    </li>
  <% end %>
</ul>
```

Okay, our tests should pass:

``` shell
$ bin/rspec spec/features/tasks_spec.rb
.

Finished in 0.04707 seconds (files took 1.31 seconds to load)
1 example, 0 failures
```

And just like that we're listing tasks!

Excellent progress so far. It may not seem like much, but we've got our
humble little `tasks` relation tucked into that controller up there. It's
happily returning data just as our ActiveRecord model might in a typical
Rails application.

[Next up](/tutorials/rails/task-relation) we're going to fine-tune our index
page and configure a task mapper so we can have convenient data-access objects
in our views rather than the plain hashes.
