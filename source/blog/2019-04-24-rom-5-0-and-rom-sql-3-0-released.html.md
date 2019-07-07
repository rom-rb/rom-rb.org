---
title: rom 5.0.0 and rom-sql 3.0.0 released
date: 2019-04-24
tags: release,announcement
author: Piotr Solnica
---

We're happy to announce the release of `rom 5.0.0` and `rom-sql 3.0.0`. Core libraries have been upgraded to work with [dry-types 1.0.0](https://dry-rb.org/news/2019/04/23/dry-types-and-dry-struct-1-0-0-released/) and as a result, schema types can now benefit from all the new dry-types features. Many significant improvements have been introduced in `rom-sql`, let's take a look at some of the new features.

### Support for arbitrary join conditions

It is now possible to set arbitrary join conditions via new DSL:

``` ruby
users.join(tasks) { |users:, tasks:|
  tasks[:user_id].is(users[:id]) & users[:name].is('John')
}
```

This will produce the following SQL:

```sql
SELECT "users"."id", "users"."name"
FROM "users"
INNER JOIN "tasks" ON (("tasks"."user_id" = "users"."id") AND ("users"."name" = 'John'))
ORDER BY "users"."id"
```

### Support for CASE statements

We've also made it simple to construct `CASE` statements, using the following DSL:

``` ruby
users.select_append {
  id.case(1 => string('one'), else: string('something else')).as(:one_or_else)
}
```

This will produce the following SQL:

```sql
SELECT
  "users"."id",
  "users"."name",
  (CASE "users"."id" WHEN 1 THEN 'one' ELSE 'something else' END) AS "one_or_else"
FROM "users"
ORDER BY "users"."id"
```

### Support for `exists` in Projection DSL

Support for `Relation#exists` was added in `2.0.0`, now it is also available within the Projection DSL. Here's an example:

```ruby
users.select_append { |posts: |
  exists(posts.where(posts[:user_id] => id)).as(:has_posts)
}
```

This will produce the following SQL:

```sql
SELECT
  "users"."id",
  "users"."name",
  (EXISTS (SELECT "tasks"."id", "tasks"."user_id", "tasks"."title" FROM "tasks" WHERE ("tasks"."user_id" = "users"."id") ORDER BY "tasks"."id")) AS "has_tasks"
FROM "users"
ORDER BY "users"."id"
```

### Improved pluck support

You can now select more than one attribute when using `Relation#pluck`:

```ruby
users.pluck(:id, :name)
# [[1, "Jane"], [2, "Joe"], [3, "Jane"], [4, "John"]]
```

### What's next?

Originally we had an ambitious roadmap for `5.0.0` release, but [its scope was simplified](https://discourse.rom-rb.org/t/changed-5-0-0-roadmap/278) so that we could ship it faster, otherwise people would be blocked with upgrading for too long. This means that everything else that didn't get into `5.0.0` will be either implemented in `5.x` series, or `6.0.0`.

You can also expect new releases of `rom-elasticsearch`, `rom-http` and `rom-yaml` adapters *soon*.

### Release information and upgrading

This is a major release with breaking changes. Please refer to [the upgrade guide](https://github.com/rom-rb/rom/wiki/5.0-Upgrade-Guide) for more information. As part of 5.0.0, following gems have been released:

* `rom 5.0.0` [CHANGELOG](https://github.com/rom-rb/rom/blob/master/core/CHANGELOG.md)
* `rom-sql 3.0.0` [CHANGELOG](https://github.com/rom-rb/rom-sql/blob/master/CHANGELOG.md)
* `rom-factory 0.8.0` [CHANGELOG](https://github.com/rom-rb/rom-factory/blob/master/CHANGELOG.md)

If you're having problems with the upgrade, please ask questions on [discussion forum](https://discourse.rom-rb.org) or [our community chat](https://rom-rb.zulipchat.com).
