---
chapter: SQL
title: Commands
---

SQL commands support all features of the standard
[ROM command API](/%{version}/learn/advanced/commands). In addition, the following
SQL-specific features are supported:

- The `associates` plugin, for connecting foreign key values when composing
  commands
- The `transaction` interface, which provides a block scope for working with
  database transactions

> #### Custom commands
> Define custom commands **only when repositories with changesets and auto-commands**
> are blocking you

### Associates Plugin

The `associates` plugin is used to automatically set foreign-key values when
using command composition.

``` ruby
class CreateTask < ROM::Commands::Create[:sql]
  relation :tasks
  register_as :create
  result :one

  associates :user, key: [:user_id, :id]
end

class CreateUser < ROM::Commands::Create[:sql]
  relation :users
  register_as :create
  result :one
end

# using command composition
create_user = rom.commands[:users][:create]
create_task = rom.commands[:tasks][:create]

command = create_user.curry(name: 'Jane') >> create_task.curry(title: 'Task')
command.call

# using command composition with arguments
command = create_user >> create_task.curry(title: 'Task')
command.call(name: 'Jane')

# using a graph
command = create_user
           .curry(name: 'Jane')
           .combine(create_article.curry(title: 'Task'))

command.call
```
