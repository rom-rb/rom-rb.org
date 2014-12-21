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
