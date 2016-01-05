# Relations

In bigger applications query logic becomes complicated very quickly. That's why
it is a good idea to break it down into smaller components. You can get pretty
far with [Repositories](/guides/basics/repositories/) but eventually you will
face a situation where encapsulating complex query inside custom relations will
be helpful.

In ROM relations are the central part of the system. They provide access to data
through internal interfaces provided by adapters and allow you to specify your
own interface for accessing *application-specific data structures*.

The fundamental design principle in ROM is that all components work with relations
rather than individual objects from relations. This means that a relation can only
return other relations (also known as "views"). Then both commands and mappers
receive a relation, do their work and return a relation back.

## Defining a relation

A relation can be defined as a class that inherits from an adapter-specific class
which is identified by adapter's name, in case of our example it's `:memory`:

``` ruby
class Users < ROM::Relation[:memory]
end
```

Alternatively you can use the routing-style DSL:

```ruby
ROM.relation(:users) do
end
```

In a relation you can define a specific [gateway](/introduction/glossary/#gateway) and [dataset](/introduction/glossary/#dataset) it takes data from, and the registered name of the relation. In the following example the default options are set explicitly:

```ruby
class Users < ROM::Relation[:memory]
  register_as :users
  gateway :default
  dataset :users
end
```

## Interface Boundaries

Relation layer in ROM clearly establishes interface boundaries. Each relation has
the internal interface provided by the adapter and allow you to define your own
interface that will be accessible in your application layer.

In example:

``` ruby
class Users < ROM::Relation[:memory]
  def by_name(name)
    restrict(name: name)
  end
end
```

This relation defines public `by_name` interface that you will be able to use in
your application. This interface uses internal `restrict` method which is provided
by the in-memory adapter.

## Lazy Relations

The top-level interface for accessing relations which is exposed by the environment
adds very powerful lazy-relation API which allows you to compose relations together
and send them through the data pipeline.

### The Data Pipeline

You can send a relation through any object that responds to `call` using common
`>>` operator:

``` ruby
ROM.use :auto_registration

ROM.setup(:memory)

class Users < ROM::Relation[:memory]
  def by_name(name)
    restrict(name: name)
  end
end

ROM.finalize

rom = ROM.env

name_list = -> users do
  users.map { |user| user[:name] }
end

user_names = rom.relation(:users) >> name_list

rom.relation(:users).to_a
# [{ id: 1, name: 'Joe', email: 'joe@example.com' }]
user_names.to_a
# ['Joe']
```

### Auto-curry

Every relation method that you defined supports auto-curry syntax which simply
means that you can reference a relation without providing method arguments:

``` ruby
users_by_name = rom.relation(:users).by_name

# call later on using short `[]` syntax
users_by_name['Jane']

# or

users_by_name.('Jane')

# or more explicit and longer form
users_by_name.call('Jane')
```

### Combining Relations

Auto-curry and data-pipeline allows very simple yet powerful feature where you
can combine results from many relations into a single relation:

``` ruby
ROM.use :auto_registration

ROM.setup(:memory)

class Users < ROM::Relation[:memory]
  def by_name(name)
    restrict(name: name)
  end
end

class Tasks < ROM::Relation[:memory]
  def for_users(users)
    restrict(user_id: users.map { |u| u[:id] })
  end
end

ROM.finalize

users = rom.relation(:users)
tasks = rom.relation(:tasks)

# combine two relations into one
users.by_name('Jane').combine(tasks.for_users)
```

As you can probably imagine this allows combining relations across different
datastores.

### Loaded Relations

A lazy relation can be materialized into a loaded relation by calling it. There
are few methods that triggers calling a lazy relation too:

``` ruby
users = rom.relation(:users).by_name('Jane')

loaded = users.call # returns a loaded relation

loaded.source # returns users
loaded.collection # returns materialized users array with tuples
```

### Accessing a Single Tuple

If you want to retrieve a single tuple from a relation you can use either `one`
or `one!` which is an intention-revealing interface resulting in an exception
when a relation includes more than one tuple.

``` ruby
# return one tuple or raise error if there's no tuples
rom.relation(:users).one

# return one tuple or raise error if there's no tuples or more than one
rom.relation(:users).one!
```
