---
title: HTTP
chapter: Relations
---

To define an HTTP relation, you can use the standard way of defining relations
in ROM:

```ruby
class Users < ROM::Relation[:http]
  gateway :placeholder
  dataset :users
end
```

The dataset name may be used by a request handler to help build the resource
path.  In the case of a namespaced resource, it is possible to provide a string
name for the dataset:

```ruby
class Users < ROM::Relation[:http]
  gateway :placeholder
  dataset 'admin/users'
end
```

To define relations that are exposed to your application, you can define your
own methods and use the internal [dataset API](/learn/http/datasets):

```ruby
class Users < ROM::Relation[:http]
  gateway :placeholder
  dataset :users

  def by_id(id)
    append_path(id.to_s)
  end

  def limit(count)
    with_params(params.merge(per_page: count.to_i))
  end
end
```
