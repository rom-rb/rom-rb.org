### Validations

ROM doesn't have validations built-in however its rails integration gives you an
ActiveModel-complaint extension that you can use for validatable parameters. To
use it you can simply include `ROM::Model::Params` into a class and define its
attributes, types and validation rules.

To create validator objects that you can inject into commands you can also
define custom classes and simply include `ROM::Model::Validator` to make it
work with ROM.

### Adding task params validation

Let's extend our task creation scenario to also check for validation errors:

``` ruby
# spec/features/tasks_spec.rb

features 'Tasks do
  fixtures :all

  scenario 'I cannot save a task without providing title' do
    visit new_task_path

    find('#task_title').set('')
    click_on 'Save'

    expect(page).to have_content('Tasks#new')
    expect(page).to have_content("Title can't be blank")
  end
end
```

We can add task parameters validation by creating `TaskParams` and `TaskValidator`
classes and configuring commands to use them:

``` ruby
# app/params
class TaskParams
  include ROM::Model::Params

  param_key :task

  attribute :title, String

  validates :title, presence: true
end

# app/validators/task_validator.rb
class TaskValidator
  include ROM::Model::Validator
end

# app/commands/tasks.rb
ROM.command(:tasks) do

  define(:create) do
    input TaskParams
    validator TaskValidator
    result :one
  end

end
```

Now it's time to tweak our controller actions and views a little bit:

``` ruby
# app/controllers/tasks_controller.rb
class TasksController < ApplicationController
  def new
    render :new, locals: { task: TaskParams.new }
  end

  def create
    attributes = params.require(:task).permit(:title)

    result = rom.command(:tasks).try { create(attributes) }

    if result.error
      render :new, locals: { task: result.error.params }
    else
      redirect_to :tasks
    end
  end
end
```

We will simply add error messages to the template:

``` erb
<h1>Tasks#new</h1>

<%= form_for task, url: tasks_path do |f| %>
  <%= task.errors.full_messages %>
  <%= f.text_field :title %>
  <%= f.submit 'Save' %>
<% end %>
```

Now the test passes:

```
$ bin/rspec spec/features/tasks_spec.rb
....

Finished in 0.14805 seconds (files took 0.3423 seconds to load)
4 examples, 0 failures
```
