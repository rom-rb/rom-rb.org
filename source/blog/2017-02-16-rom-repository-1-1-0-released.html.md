---
title: rom-repository 1.1.0 released
date: 2017-02-16
tags: release,announcement,repository
author: Piotr Solnica
---

Today we've released a new version of rom-repository which ships with new features and a couple of bug fixes. This release focused on improving auto-mapping capabilities and making it more flexible when you want to use custom mappers.

## Adjusting relation nodes when loading aggregates
It's now possible to adjust individual relation nodes when you're loading aggregates or composing relations manually. This feature allows you to apply additional restrictions, or use custom views, or even set custom mappers on-the-fly.

Let's say we want to load users with their priority tasks:

``` ruby
aggregate(:tasks).
  node(:tasks) { |tasks| tasks.where { priority < 3 }
```

This also works with deeply nested nodes:

``` ruby
aggregate(orders: :lines).
  node(orders: :lines) { |lines| lines.where(id: line_ids) }
```

## Disabling auto-mapping to structs

By default all repositories map plain hashes to `ROM::Struct` objects, you can now disable this feature. This is useful in situations like mapping to JSON where intermediate objects are simply not needed, or when you want to use custom mappers that require hashes rather than structs.

You can disable mapping to structs using a repo class option:

``` ruby
class UserRepo < ROM::Repository[:users]
  auto_struct(false)
end

user_repo = UserRepo.new(rom)
user_repo.users.to_a
# [{:id=>1, :name=>"Jane"}]
```

or when instantiating a repo object:

``` ruby
user_repo = UserRepo.new(rom, auto_struct: false)
```

or at run-time per individual relation:

``` ruby
class UserRepo < ROM::Repository[:users]
  def user_hashes
    users.with(auto_struct: false).to_a
  end
end

user_repo = UserRepo.new(rom)
user_repo.user_hashes
# [{:id=>1, :name=>"Jane"}]
```

## Improved support for wrapping

Just like `combine`, `wrap` now accepts association names. This simplifies loading nested data structures via joins. Here's a simple example:

``` ruby
class Tasks < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      belongs_to :user
    end
  end
end

class TaskRepo < ROM::Repository[:tasks]
  def with_user(id)
    tasks.wrap(:user).by_pk(id).one
  end
end

task_repo = TaskRepo.new(rom)

task_repo.with_user(id)
# #<ROM::Struct[Task] id=1 user_id=1 title="A task" user=#<ROM::Struct[User] id=1 name="Jane">>
```

## Using custom mappers along with auto-mapping
You can now use `auto_map` option in `map_with` method which will apply auto-mapping before applying your own mappers. This is useful in cases where you want to use custom mappers and you want auto-mapping to handle complex structural transformations like merging multiple data sets into nested structures (which is what happens when you compose relations using `aggregate` or `combine`).

To enable auto-mapping with custom mappers, simply pass `auto_map: true` option, this way you don't have to worry about handling aggregates manually, as your mappers will be applied to already transformed data:

``` ruby
class UserRepo < ROM::Repository[:users]
  relations :tasks
  
  def custom_mapping
    aggregate(:tasks).
      map_with(:my_custom_mapper, auto_map: true)
  end
end
```

## Release Details

This is a backward compatible upgrade, for more information check out the [CHANGELOG](https://github.com/rom-rb/rom-repository/blob/master/CHANGELOG.md#v110-2017-02-16). If you found any issues, or have trouble upgrading, please [report it](https://github.com/rom-rb/rom-repository).