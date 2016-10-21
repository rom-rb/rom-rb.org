---
chapter: SQL
title: Relations
---

To define an SQL relation you can use the standard way of defining relations in
ROM:

``` ruby
class Users < ROM::Relation[:sql]
end
```

By default relation's `dataset` name is inferred from the class name. You can
override this easily:

``` ruby
module Relations
  class Users < ROM::Relation[:sql]
    dataset :users
  end
end
```

To define relations that are exposed to your application you can define your own
methods and use internal [query DSL](#query-dsl):

``` ruby
class Users < ROM::Relation[:sql]
  def by_id(id)
    where(id: id)
  end
end
```

Remember that relation methods must always return other relations, you shouldn't
return a single tuple.
