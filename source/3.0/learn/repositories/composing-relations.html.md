---
chapter: Repositories
title: Composing Relations
---

Composing relations means defining various subsets of data in ways that make
them composable into complex structures. A good example of relation composition
is loading aggregates where two or more subsets of data are being merged into
a nested data structure using in-memory transformation. This is a simple, yet
powerful technique, as it allows us to compose data however we want, and it works
cross-database too.

In order to be able to compose relations, we need two things - a unique identifier
and a list of attributes that a given relation tuples have. To accomplish that
we use a special syntax that allows you to define composable <mark>relation views</mark>.
You could think of these views just like actual SQL views in a database.

Here's a simple example:

``` ruby
class Posts < ROM::Relation[:sql]
  schema(infer: true)

  view(:listing, [:id, :user_id, :title, :published_at]) do
    select(:id, :title, :user_id, :published_at).order(:published_at)
  end
end
```

Let's define another view so that we will be able to compose users and posts:

``` ruby
class Users < ROM::Relation[:sql]
  schema(infer: true)

  view(:authors, [:id, :name]) do |posts|
    select(:id, :name).where(id: posts.pluck(:user_id)).order(:name)
  end
end
```

This way we defined two views:

- `Posts#listing` which includes `:user_id` key
- `Users#authors` which narrows down the relation based on posts' `:user_id` keys

Having that, we can compose posts with their authors using our custom views via
post repository:

``` ruby
class PostRepo < ROM::Repository[:posts]
  relations :users

  def listing
    posts.listing.combine_parents(one: { author: users.authors })
  end
end
```

Check out [API documentation](http://www.rubydoc.info/github/rom-rb/rom-repository/ROM/Repository/RelationProxy/Combine)
for all types of compositions that are available in repositories.

## When to use custom compositions?

In many common cases using canonical asociations will be sufficient, which means
that you simply define associations in schemas and
[read aggregates](/%{version}/learn/repositories/reading-aggregates); however, you will find
situations where custom views, with smaller data sets and more optimizied queries
are useful too. You will also find this to be useful when you'd like to compose
data that are fetched from multiple data sources (ie an SQL database and an HTTP API).

Relation composition helps you shape your data structures in ways that match your
application's domain. Rather than using canonical representation defined by the
database schemas, you can create simpler and more optimized representation of the
data, which simplifies your domain layer.
