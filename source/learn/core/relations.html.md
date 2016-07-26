---
title: Core
chapter: Relations
---

Relations are really the heart of ROM. They provide APIs for reading the data
from various databases, and low-level interfaces for making changes in the databases.
Relations are adapter-specific, which means that each adapter provides its own
relation specialization, exposing interfaces that make it easy to leverage the
features of your database. At the same time, these relations encapsulate data
access, so that details about how it's done don't leak into your application domain
layer.

## Relation classes

In typical setup of an application using ROM, relations are defined as explicit
classes. You can put them in separate files, namespace them or not, and configure
them when it's needed (especially useful when using a legacy database with non-standard
naming conventions).

The most important responsibility of relations is to expose a clear API for reading
data. Every relation *method* should return another relation, we call them
<mark>relation views</mark>. These views can be defined in ways that make them
*composable* by including join-keys in the resulting tuples. This is not limited
to SQL, you can compose data from different sources.

### Example relation class

Even when you use an adapter that can infer relations from your database schema,
it is valuable to define relations classes explicitly. Let's say we have `:users`
table in an SQL database, here's how you would define a relation class for it:

``` ruby
class Users < ROM::Relation[:sql]
end
```

Notice two things:

- `ROM::Relation[:sql]` uses `:sql` identifier to resolve relation type for `rom-sql`
  adapter
- `Users` class name is used by default to infer `dataset` name and set it to `:users`

### Relation methods

Every method in a relation should return another relation, this happens automatically
whenever you use a query interface provided by adapters. In our example we use
`rom-sql`, let's define a relation view using SQL query DSL:

``` ruby
class Users < ROM::Relation
  def listing
    select(:id, :name, :email).order(:name)
  end
end
```

### Next

Now let's see how you can use [relation schemas](/learn/core/schemas).
