## Extending the Task relation

ROM splits data access into two parts: [relations](/introduction/relations)
and [mappers](/introduction/mappers). Inside relations we define how we fetch
the data and with mappers we define how the data is presented to our
application layer.

We've already seen simple examples of using relations to retrieve task data.
What if we wanted something a little more complicated? Like displaying the
tasks on our index page ordered by the task title.

To do that, we need to extend our relation with a method that tells the
underlying adapter what to do.

We know we want the tasks ordered by title for the index view. Specify how
you want the data returned from this new `index_view` method:

```ruby
# spec/relations/task_spec.rb

require 'rails_helper'

describe 'Tasks relation' do
  fixtures :tasks

  describe 'index_view' do
    it 'returns tasks sorted by name' do
      tasks = ROM.env.read(:tasks).index_view

      expect(tasks.to_a).to eql(
        [{:id=>1, :title=>"Task One"}, {:id=>2, :title=>"Task Two"}]
      )
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

  1) Task relation index_view returns tasks sorted by name
     Failure/Error: tasks = ROM.env.read(:tasks).index_view
     ROM::NoRelationError:
       undefined relation :index_view within "tasks"
       # backtrace...

Finished in 0.00663 seconds (files took 0.2345 seconds to load)
1 example, 1 failure

Failed examples:

rspec ./spec/relations/tasks_spec.rb:7 # Task relation index_view returns tasks sorted by name
```

Time to define our missing relation:

``` ruby
# app/relations/tasks.rb

ROM.relation(:tasks) do
  def index_view
    select(:id, :title).order(:title)
  end
end
```

Run it again to see it pass!

``` shell
$ bin/rspec spec/relations/tasks_spec.rb

.

Finished in 0.0127 seconds (files took 0.23984 seconds to load)
1 example, 0 failures
```

### What have we done?

We added a dedicated method to our relation and it ordered our results. Why is
that important?

To make `index_view` work, we used methods on the
[adapter](/introduction/adapters) to access and order the data. In fact, if
you've used [Sequel](https://github.com/jeremyevans/sequel) before both the
`#select` and `#order` methods should look familiar to you. They're dataset
methods and they're the reason the adapter + relation concept is so powerful.

Using methods like this on relations prevents the rest of our application from
knowing how data is retreived from the datastore. We're able to use the full
capabilities of Sequel here while keeping our application blissfully unaware of
the details. In addition, our data access is **explicit**. This isn't a query
interface that can perform arbitrary actions on our data. The methods are
methods we define, named for the use-case (we hope!), and they are chainable as
we would expect.

We've got an array of hashes orderd according to our specifications. What about
getting this data into our own Domain Objects? That's where we're going
[next](/tutorials/rails/task-mapper).
