---
chapter: Repositories
title: Sessions
---

When you want to perform many operations at once and use a transaction, repositories
provide a session API to achieve that via `Repository#session` method. It yields
a session object to the block and queues your changesets to be persisted in a transaction.

## Saving a single changeset

``` ruby
changeset = user_repo.changeset(name: 'Jane')

user_repo.session do |s|
  s.add(changeset)
end
```

## Saving a changeset with association

If you configured associations in your schemas, you can associate changesets easily:

``` ruby
user_changeset = user_repo.changeset(name: 'Jane')
task_changeset = task_repo.changeset(title: 'Task 1')

user_repo.session do |s|
  s.add(user_changeset.associate(task_changeset, :user))
end
```

## Using different changeset types

You can use all changeset types within the same session, let's say we want update and create:

``` ruby
user = user_repo.fetch(1)

user_changeset = user_repo.changeset(task_count: user.task_count + 1)
new_task_changeset = task_repo.changeset(title: 'Another task')

user_repo.session do |s|
  s.add(new_task_changeset.associate(user, :user)
  s.add(user_changeset)
end
```
