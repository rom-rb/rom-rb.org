## Displaying Tasks

Now that we’ve [integrated ROM with Rails](/tutorials/rails/getting-started) and briefly visited ROM’s high level API for relations and commands, it’s time to dive a little deeper into the capabilities of ROM.

This section is focused on how to select data using ROM relations and construct model objects using ROM mappers. After reading this, you’ll have an understanding of:

- How to use ROM relations to set up read queries.
- How to integrate ROM with Rails controllers.
- What ROM relations are, and how they differ from ActiveRecord and Sequel models.
- What ROM mappers are, and how they can be used to build rich domain models.

We’ll start by building an index page to display all the tasks in our todo list.

### An Index Action

To read data from the tasks relation that we set up previously, make a route to a new controller in `app/controllers/tasks_controller.rb`.

If you don’t want to do this manually, you can generate the controller with the following command:

```shell
bin/rails g controller tasks
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

Sending a request to this action will give us an error due to a missing template. So let’s fill that in now:

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

And just like that, we’re listing tasks!

Notice that we’re using raw hash keys to access the task attributes in the template. This is because the relation doesn’t know how to map the list of tasks to a particular model.

Before addressing this, let’s first explore how to set up more granular queries on the relation.

### Filtering

The specific capabilities of a relation depend on the dataset adapter it’s configured with. Here, we’re using [rom-sql](https://github.com/rom-rb/rom-sql), which gives us access to the [Sequel Dataset API](http://sequel.jeremyevans.net/rdoc/classes/Sequel/Dataset.html).

To filter the list of tasks based on whether or not the tasks are complete, add the following

```ruby
# app/relations/tasks.rb

class Tasks < ROM::Relation[:sql]
  def by_complete
    where(is_complete: true)
  end

  def by_incomplete
    where(is_complete: false)
  end
end
```

Note that in Sequel, `filter` can also be used as an alias for `where`. Use whichever style you prefer.

To render these filtered lists in the index template, we’ll introduce the new concept of a task status.

The database table for tasks has a boolean `is_complete` field, but `status` maps more closely to the mental model for tasks that we want in our user interface.

In practice of course, we’d like our database fields to map as directly as possible to the data structures and concepts in our application, but this isn’t always possible or straightforward.

Here, we’re going to deliberately use the subtle mismatch between `status` and `is_complete` to highlight some of the capabilities of ROM and how its philosophy differs from ActiveRecord.

Start by adding the status filters directly to the index action:

```ruby
# app/controllers/tasks_controller.rb

class TasksController < ApplicationController
  def index
    if params[:status] == 'complete'
      tasks = rom.relation(:tasks).by_complete
    elsif params[:status] == 'incomplete'
      tasks = rom.relation(:tasks).by_incomplete
    else
      tasks = rom.relation(:tasks)
    end

    render locals: { tasks: tasks }
  end
end
```

This works, but it’s a far more messy and ad-hoc than we’d like. Let’s quickly refactor it to get rid of a few code smells.

First, we’ll push access to the relation behind a private method in the controller. Because our route handles matching valid parameters, the extra conditional in the action isn’t needed—we can call the associated method on the relation by sending the parameter name as a symbol.

```ruby
# app/controllers/tasks_controller.rb

class TasksController < ApplicationController
  def index
    render locals: { tasks: index_view(params[:status]) }
  end

  private

  def index_view(status)
    if status
      rom.relation(:tasks).send(status.to_sym)
    else
      rom.relation(:tasks)
    end
  end
end
```

Another approach we could consider is to lift the index view into the relation itself. This has the advantage of separating 

### Method chaining

Let’s dive a little deeper, and break down what happens when we access the `tasks` relation on the ROM environment:

From a Rails perspective, one way to look at the high level ROM API is a supercharged tightly packed implementation of the registry pattern.

https://mattbrictson.com/registry-pattern

```ruby
rom.relation(:tasks)
```

This gives us a freshly loaded instance of the relation to play with.

Our Rails app template generated a `Tasks` relation class in `app/relations/task.rb`. To add specific query capabilities to the relation, we add them as methods in this class.

Any methods we define on the relation class become application specific behaviour.

For example, we may want to order our list of tasks by priority:

```ruby
class Task < ROM::Relation[:sql]
  def priority
    order(priority: :desc)
  end
end
```





Depending on the specific methods defined on that relation’s class, 

In the app we’re building here, the `tasks` relation refers directly to the database table we’re querying, but the key thing to understand is that it doesn’t have to.

We can use the same interface of named relations to access data from anywhere—REST APIs, NoSQL databases, even YAML and CSV files. All data comes back through a uniform interface that responds to `#each` and yields hashes.

Everything else on a relation is defined by its specific class.

You can see this in action by adding new query methods to `app/relations/task.rb` and seeing how they affects the .

```

```



