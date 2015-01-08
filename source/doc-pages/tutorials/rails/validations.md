## Validations and error handling

ROM doesn't have validations built-in. In contrast to the all-in-one approach
commonly found in Rails projects, we're going to handle validation a little
differently. We would normally pass in a `Task` model and validate it but our
tasks are value objects, and simple ones at that. They have no concept of if
they are _valid_ or not.

Since we can't validate a `Task` we'll need to provide something that knows how
to define what a valid task looks like. That will be a `TaskParams` object. The
`rom-rails` gem provides an ActiveModel-compliant extension that you can use
for validatable parameters. To use it you can simply include
`ROM::Model::Params` into a class and define the attributes, types and
validation rules.

A params object isn't the entire story. It knows what a valid `Task` is but it
doesn't know how to run those validations -- for that we need a validator.  To
create validator objects that can be injected into commands you define custom
classes and simply include `ROM::Model::Validator`.

Let's see how we do this for tasks.

### Task validations

#### Specify how the validations should behave

Extend the task creation scenario to also check for validation errors related
to a blank title:

``` ruby
# spec/features/tasks_spec.rb

features 'Tasks' do
  # ...

  scenario 'I cannot save a task without providing title' do
    visit new_task_path

    find('#task_title').set('')
    click_on 'Save'

    expect(page).to have_content('Tasks#new')
    expect(page).to have_content("Title can't be blank")
  end
end
```

As expected, this will fail if we run it:

``` shell
$ bin/rspec spec/features/tasks_spec.rb
...F

Failures:

  1) Tasks I cannot save a task without providing a title
     Failure/Error: expect(page).to have_content('Tasks#new')
       expected to find text "Tasks#new" in "Tasks#index Task One Task Two"
     # backtrace ...

Finished in 0.21855 seconds (files took 0.2381 seconds to load)
4 examples, 1 failure

Failed examples:

rspec ./spec/features/tasks_spec.rb:34 # Tasks I cannot save a task without providing a title
```

The application is happily creating a task with a blank title! That's no good.

#### TaskParams

We have already mentioned a params object and as you know params are handled in
our controllers. While we haven't created the `TaskParams` object yet let's see
how and where it shows up in `TasksController`. Add the `new` action:

``` ruby
# app/controllers/tasks_controller.rb

class TasksController < ApplicationController
  # ...

  def new
    render :new, locals: { task: TaskParams.new }
  end

  # ...
end
```

By this we can deduce that our views will see a `TaskParams` instance rather
than a `Task`. Let's look at that params object now:

``` ruby
# app/models/task_params.rb

class TaskParams
  include ROM::Model::Params

  param_key :task
  attribute :title, String
  validates :title, presence: true
end
```

There is a lot going on in a small amount of code. First off we define our class
and include `ROM::Model::Params` which is provided by `rom-rails`.

Next, we tell the object what our `param_key` is:

  `param_key :task`

Then, what attributes should be included and their type:

  `attribute :title, Sting`

Last but not least, we add the validation line:

  `validates :title, presence: true`

That last bit should look familiar. It's straight out of Rails. In fact,
`rom-rails` uses `ActiveModel::Validations`. (If you're interested in how this
all fits together you can puruse the small implementation of
[`ROM::Model`](https://github.com/rom-rb/rom-rails/blob/master/lib/rom/model.rb)


We can add task parameters validation by creating `TaskParams` and `TaskValidator`
classes and configuring commands to use them:

#### TaskValidator

While our new params object helps us understand what a valid task looks like, it
doesn't actually **run** those validations. In keeping with ROMs ideas of
[command query separation](/introduction/commands), validation is done with a
Validator.

``` ruby
# app/models/task_validator.rb

class TaskValidator
  include ROM::Model::Validator
end
```

All this does is raise validation errors unless the validatable object passed in
is valid.

#### Putting it all together in a command

The Params and Validator objects are nice but they don't do anything for our
application until composed together. [Commands](/introduction/commands) give
us the perfect place to do just that:

``` ruby
# app/commands/tasks.rb

ROM.command(:tasks) do
  define(:create) do
    input TaskParams
    validator TaskValidator
    result :one
  end

  # ...
end
```

Here's our original implementation of `create` for comparison:

``` ruby
define(:create) do
  result :one
end
```

We added `input` and `validator` to tell the command how it should process
the data.

At this point we actually have working validations but we're not handling the
validation errors in our controller nor are we providing any feedback to the
user.

### Handling errors

The `TaskValidator` will raise errors inside our `create` command when there are
validation problems. That means we will see those errors in the result object
that is returned from the command.

``` ruby
# app/controllers/tasks_controller.rb

class TasksController < ApplicationController
  # ...

  def create
    # Rails 'strong parameters'
    attributes = params.require(:task).permit(:title)
    # Now we capture the command result
    result = rom.command(:tasks).try { create(attributes) }

    if result.error
      render :new, locals: { task: result.error.params }
    else
      redirect_to :tasks
    end
  end
end
```

And we can add these messages to our template:

``` erb
# app/views/tasks/new.html.erb

<h1>Tasks#new</h1>

<%= form_for task, url: tasks_path do |f| %>
  <%= task.errors.full_messages %>
  <%= f.text_field :title %>
  <%= f.submit 'Save' %>
<% end %>
```

#### Passing tests!

```
$ bin/rspec spec/features/tasks_spec.rb
....

Finished in 0.14805 seconds (files took 0.3423 seconds to load)
4 examples, 0 failures
```

### Keep it separated

This section on validations and errors serves to further drive home the point
that our ROM-based applications are composed of lots of small pieces working
together. Yes, we created two additional objects to handle validations. What
did we gain through this seeming extra work?

Where would you look to understand how a valid `Task` is represented? The
model, the params, the validator? Right. We have a single place to look --
the `TaskParams` object. That should have some nice impacts on what we test
and were as well.

What about the validation process itself? We have a thin object that just
gives us access to the ROM wrapper around `ActiveModel::Validations`. There
is so much less to understand _for a single feature_ than our typical Rails
model.

Is this [the end](/tutorials/rails/the-end)?
