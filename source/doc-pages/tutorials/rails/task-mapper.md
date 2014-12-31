## Setting up Task mapper

We just extended our task relation with a method for the index view. The data
return from this method is an array of hashes -- the most basic representation
of data in ROM.

These hashes may be all you need but, more often than not, you'll want to use a
proper domain object. The "M" in ROM stands for **M**apper and it is through a
mapper that we'll transform our hashes into something a little more useful.

To start, we'll need to define an object for the mapper to use. It can be
whatever kind of object you like. Be it a plain PORO or something more
sophisticated. The only contract is that it must accept an attribute hash in the
constructor.

We're using
[Virtus value objects](https://github.com/solnic/virtus/#value-objects)
because they already support the required attribute hash construction and nice
bonus features out-of-the-box like equality methods.

``` ruby
# app/models/task.rb

class Task
  include Virtus.value_object(coerce: false)

  values do
    attribute :id, Integer
    attribute :title, String
  end
end
```

With an entity class defined we can simply instruct the task mapper to use it.

``` ruby
# app/mappers/tasks.rb

ROM.mappers do
  define(:tasks) do
    model Task
  end
end
```

Notice how little we have add to the mapper definition. Running the specs again
will illustrate how this change impacts our application:

``` shell
$ bin/rspec

  # ...

  expected: [{:id=>1, :title=>"Task One"}, {:id=>2, :title=>"Task Two"}]
       got: [#<Task id=1 title="Task One">, #<Task id=2 title="Task Two">]

  # ...
```

The task relation spec is now failing as it expects hashes. Update it to
reflect the changes we made:

``` ruby
# spec/relations/task_spec.rb

require 'rails_helper'

describe 'Tasks relation' do
  fixtures :tasks

  describe 'index_view' do
    it 'returns tasks sorted by name' do
      tasks = ROM.env.read(:tasks).index_view
      task_one = Task.new(id: 1, title: "Task One")
      task_two = Task.new(id: 2, title: "Task Two")

      expect(tasks.to_a).to eql([task_one, task_two])
    end
  end
end
```

And we're green!

``` ruby
$ bin/rspec spec/relations/tasks_spec.rb
.

Finished in 0.00746 seconds (files took 0.22541 seconds to load)
1 example, 0 failures
```

### Using dedicated task relation for index view

We've defined the relation for the index view and a mapping to return a `Task`
instead of hashes. It's time to update the controller and the index template
for the changes.

If you remember, our goal was that the list of tasks was ordered by the task
title. We created the `index_view` relation method for tasks.

``` ruby
# app/controllers/tasks_controller.rb

class TasksController < ApplicationController
  def index
    render locals: { tasks: rom.read(:tasks).index_view }
  end
end
```

The view is now getting a list of `Task` objects so we want to use the accessor
method instead of `[]`.

``` erb
# app/views/tasks/index.html.erb

<h1>Tasks#index</h1>

<ul>
  <% tasks.each do |task| %>
    <li>
      <%= task.title %>
    </li>
  <% end %>
</ul>
```

### Summing up

We "graduated" from simple hashes to a rich entity object to ease data access
in the views. The `Task` entity looks similar to the standard `ActiveRecord`
objects we normally see in a Rails project. There are some important differences
however. Our `Task`:

* is a [value object](http://www.c2.com/cgi/wiki?ValueObject). __(Remember that
ROM can use any object that accepts a hash of attributes.)__
* exposes only required information -- the title attribute
* doesn't support validation
* doesn't support persistance
* can't be changed
* has no database query DSL
* doesn't support serialization

The above features aren't needed to meet our design goals. The ROM team
believes that each layer of an application should only have the data, and data
access, it requires, and no more. Looking at the controller above, the action is
still expressive -- we know what data is being passed to the view. We still have
the attribute accessor in the view so no surprises there.

We don't need to understand a large amount of unrelated and unneccessary
features in a context where they're not required.

Okay, only include what we need, sounds great. Now we need to create and update
tasks. In [managing tasks](/tutorials/rails/managing-tasks) we will see how to
implement these actions.
