---
title: ROM 3.0 Released
date: 2017-01-30
tags: release,announcement
author: Piotr Solnica
---
We're happy to announce the release of rom 3.0.0, a big release which comes with the first stable versions of rom-sql 1.0.0 and rom-repository 1.0.0. Changes and improvements in rom core gem focused mostly on extending functionality of relation Schema API and Command API, as well as removing all deprecated core APIs. The biggest highlight are new features in rom-sql and rom-repository.

## Extended Schemas

Starting from rom 3.0.0 **all relations, regardless of the adapter, have schemas**. It means that Schema is now a 1st class API available in all adapters.

Schemas now use adapter-specific attribute types, which allowed us to implement all kinds of new features in rom-sql that make building complex queries much simpler. We also improved schema inference and added support for more PostgreSQL types like `enum`, `point` or `inet`. Furthermore, it's now possible to use inference along with explicit attribute definitions, which is useful in cases where inferrer doesn't support some custom column type, or when you simply want to customize your schema.

### Advanced projections

Relation schemas are **always available**, they keep track of the current attributes that relation tuples will include. This is a huge improvement, since previously schemas were only the representation of canonical relations (defined by your actual database schema). Projections go through schemas, and they adjust their attributes automatically. This gives us complete information about data that any relation can return.

In rom-sql schema attributes are extended with SQL-specific features, which allows queries like this:

``` ruby
class Users < ROM::Relation[:sql]
  schema(infer: true)
  
  def emails
    select { [email, int::count(id).as(:count)] }.
      group(:email).
      order(:email)
  end
  # SELECT "email", COUNT("id") AS "count"
  #  FROM "users"
  #  GROUP BY "email"
  #  ORDER BY "email"
end
```

You can use both blocks or refer to attributes directly through `Relation#[]` method which returns schema attributes identified by their canonical names:

``` ruby
class Users < ROM::Relation[:sql]
  schema(infer: true)
  
  def emails
    select(self[:email], self[:id].func { int::count(id).as(:count) }).
      group(:email).
      order(:email)
  end
  # SELECT "email", COUNT("id") AS "count"
  #   FROM "users"
  #   GROUP BY "email"
  #   ORDER BY "email"
end
```

Resulting relation views include complete information about their current schema:

``` ruby
users.duplicated_emails.schema.attributes
# [
#   #<ROM::SQL::Attribute[NilClass | String] name=:email source=ROM::Relation::Name(users)>,
#   #<ROM::SQL::Function[Integer] func=#<Sequel::SQL::Function @name=>"COUNT", @args=>[#<ROM::SQL::Attribute[Integer] primary_key=true name=:id source=ROM::Relation::Name(users)>], @opts=>{}> alias=:count>
# ]
```

This plays a major role in automatic mapping in repositories, as they can define structs with all attribute type information provided by relations.

### Support for SQL functions
The `count` function we used in the previous example probably caught your attention—this is a new feature which allows you to use any SQL function with arbitrary arguments, including relation attributes, or **anything** that can be dumped into a valid SQL. The syntax is always:

``` ruby
type_annotation::function_name(*arguments)
```

It returns a `ROM::SQL::Function` object which works like any other schema attribute, and you can qualify it or provide an alias, or use a boolean expression with various operators. Functions work with `select`, `order` and `where`. The only difference is that `select` requires a type annotation, and the other methods don't.

Here's another example:

``` ruby
class Users < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      has_many :tasks
    end
  end
  
  def busy_people
    select(:id, :name, tasks[:id].func { int::count(id).as(:task_count) }).
      left_join(tasks).
      group(:id).
      having { count(id.qualified) > 1 }
  end
  # SELECT "users"."id", "users"."name", COUNT("tasks"."id") AS "task_count"
  #   FROM "users"
  #   LEFT JOIN "tasks" ON ("users"."id" = "tasks"."user_id")
  #   GROUP BY "users"."id"
  #   HAVING (count("users"."id") > 1) ORDER BY "users"."id"
end
```

Maybe you noticed that we passed `tasks` relation object to `left_join`—this is another new feature.

### Improved joins

You can now pass relation objects to `join`, `left_join` and `right_join`, and, assuming you configured associations, your relation will do the work for you to join the correct table with join conditions already set. Furthermore, it will be automatically qualified. Here's what it means:

``` ruby
class Tasks < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      belongs_to :user
    end
  end
  
  def with_user
    # "join(:users, user_id: :id).qualified" becomes:
    join(users)
  end
end
```

There's also a new method to simplify finding all associated tuples through associations, called `Relation#assoc`, it uses configured associations to prepare a joined relation for you. Let's say we want to find all user priority tasks:

``` ruby
class Users < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      has_many :tasks
    end
  end
  
  def priority_tasks(user_ids)
    assoc(:tasks).
      select(:id, :title, self[:name].qualified.as(:user))
      where(priority: 1, user_id: user_ids)
  end
end

users.priority_tasks([1, 2, 3])
# SELECT "tasks"."id", "tasks"."user_id", "tasks"."title", "users"."name" AS "user"
#   FROM "tasks"
#   INNER JOIN "users" ON ("users"."id" = "tasks"."user_id")
#   WHERE ("priority" = 1) AND ("user_id" IN(1, 2, 3))
#   ORDER BY "tasks"."id"
```

### Custom association views

Another interesting feature is the ability to **extend** default association relations with a custom view. This is useful in cases where you would like to add more attributes to the resulting relation, change order etc.

Let's say we have users with accounts, and would like to include `position` from the join table and order accounts by that column:

``` ruby
class Users < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      has_many :accounts, through: :users_accounts, view: :ordered
    end
  end
end

class Accounts < ROM::Relation[:sql]
  schema(infer: true)

  view(:ordered) do
    schema do
      append(users_accounts[:position])
    end

    relation do
      order(:position)
    end
  end
end
```

We use View DSL in this case, as it provides schema information up-front, before a relation is even initialized. It's one of the core features in rom that allows defining composable relations. Associations are based on this feature, but you can use it without associations too.

### Bi-directional coercions

In the first version of Schema API, canonical attribute types were used by commands exclusively. Starting with rom 3.0.0 you can also define `read` attributes, which will be used by relations when they read their tuples.

Let's say we have address JSONB column, and we want a custom address object back that uses JSONB attributes:

``` ruby
Address = Struct.new(:country, :city, :street, :zipcode)

class Users < ROM::Relation[:sql]
  AddressType = Types.Constructor(Address) { |value| Address.new(*value) }
    
  schema(infer: true) do
    attribute :address, Types::PG::JSONB, read: AddressType
  end
end

users.select(:address).to_a
# [{:address=>#<struct Address country="Poland", city="Krakow", street="Street 1"}]
```

For now this is very explicit, in the near future we'll add various convention-based improvements, so that specifying `read` types is more concise.

## Improved repositories

We added support for transactions, custom commands in changesets, run-time changeset mapping with custom blocks, associating data via changesets, asking for custom objects when committing a changeset... check out [updated docs](http://rom-rb.org/learn/repositories/changesets/) to learn more, and here are some of the highlights.

### Comitting changesets

Changesets are now standalone objects, with a new `Changeset#commit` method which allows you to store them conveniently in your database.

Here's a simple example of a changeset which saves a new user:

``` ruby
# assuming we have a repo like that:
class UserRepo < ROM::Repository[:users]
end

user_repo.changeset(name: "Jane", email: "jane@doe.org").commit
# => {:id=>1, :name=>"Jane", :email=>"jane@doe.org"}
```

### Committing changesets via repositories
Changesets simply return whatever your database returned, but you can commit them via repositories that will convert raw data to rom structs:

``` ruby
# assuming we have a repo like that:
class UserRepo < ROM::Repository[:users]
  command :create
end

new_user = user_repo.changeset(name: "Jane", email: "jane@doe.org")

user_repo.create(new_user)
# => #<ROM::Struct[User] id=1 name="Jane" email="jane@doe.org">
```

### Powerful data transformations

Changeset now support custom data transformations, with many builtin functions provided by [transproc](https://github.com/solnic/transproc) gem. You can define your custom changeset classes and specify how data must be transformed before we can pass it to the underlying database command:

``` ruby
class NewUser < ROM::Changeset::Create[:users]
  map do
    unwrap :address, prefix: true
  end
end

new_user = user_repo.changeset(NewUser).data(
  name: "Jane",
  address: {
    city: "Krakow", country: "Poland", street: "Street 1", zipcode: "1234"
  }
)

new_user.commit
# => {:id=>1, :name=>"Jane", address_city: "Krakow", address_country: "Poland", address_street: "Street 1", address_zipcode: "1234"}
```

You can also pass an argument to `.map` and in that case you can use arbitrary code to perform a transformation. Check out [docs](http://rom-rb.org/learn/repositories/custom-changesets/) to learn more.

## Support for nested aggregates

If you specified your associations in relations, you can use a simplified interface for fetching aggregates through repositories. For example if you have users with tasks, and tasks have tags, and you want to load a user aggregate with more levels of nesting, you can now do this:

``` ruby
class UserRepo < ROM::Repository[:users]
  relations :tasks, :tags
end

user_repo.aggregate(tasks: :tags)
```

Check out [Repository#aggregate](http://www.rubydoc.info/gems/rom-repository/ROM/Repository/Root#aggregate-instance_method) API docs for more information.

## Detailed release information

As part of this release following gems have been published:

* rom 3.0.0 [CHANGELOG](https://github.com/rom-rb/rom/blob/master/CHANGELOG.md#v300-2017-01-29)
* rom-sql 1.0.0 [CHANGELOG](https://github.com/rom-rb/rom-sql/blob/master/CHANGELOG.md#v100-2017-01-29)
* rom-repository 1.0.0 [CHANGELOG](https://github.com/rom-rb/rom-repository/blob/master/CHANGELOG.md#v100-2017-01-29)
* rom-rails 0.9.0 [CHANGELOG](https://github.com/rom-rb/rom-rails/blob/master/CHANGELOG.md#v090--2017-01-30)

Please check out [rom-rb.org](http://rom-rb.org) as it was updated with more documentation!

## Upgrading

Please do read [rom-sql 1.0.0 upgrade guide](https://github.com/rom-rb/rom-sql/wiki/Upgrading-from-0.9.x-to-1.0.0) as it includes useful information. Making the transition should not be difficult, many applications (including big ones), have been already upgraded during beta/RC testing, and it was a smooth process.

If you have problems with the upgrade, please report an issue or ask for help on [the discussion forum](https://discuss.rom-rb.org).

## Thank you!

This is a long post, and it barely covers ~20% of what was improved or added, it was a huge effort to get here and I would like to thank all of the contributors, for their PRs, reported issues, and testing beta/rc releases early!

Special thanks go to (in no particular order):

* [Nikita Shilnikov](https://github.com/flash-gordon), for his fantastic work on schema inferrers, helping *a lot* with rom-support removal by putting together [dry-core](https://github.com/dry-rb/dry-core) and porting **all rom gems** to use dry-initializer
* [Sergey Kukunin](https://github.com/Kukunin) for his help with [transproc 1.0.0](https://github.com/solnic/transproc/blob/master/CHANGELOG.md#v100-2017-01-29) (yes, we released that too!) and helping with rom-repository mapping pipeline
* [Andrew Kozin](https://github.com/nepalez/) for his work on [dry-initializer](https://github.com/dry-rb/dry-initializer) which now plays major role in **many** core objects in rom projects and allowed us to get rid of rom-support

## What happens next?

We have big plans for future releases, but hopefully we'll manage to provide more frequent, incremental improvements now that rom-sql and rom-repository are stable. More details will be revealed soon, stay tuned!

I hope you'll find this release useful, if you have problems or any kind of feedback, please report issues or just [talk to us](https://gitter.im/rom-rb/chat).

If you happen to attend [RubyConf AU](http://rubyconf.org.au) next week, be sure to say hi! :)
