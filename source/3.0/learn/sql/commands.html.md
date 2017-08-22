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
create_user = rom.command(:users).create
create_task = rom.command(:tasks).create

command = create_user.with(name: 'Jane') >> create_task.with(title: 'Task')
command.call

# using a graph
command = rom.command([
  { user: :users }, [:create, [{ task: :tasks }, [:create]]]
])

command.call user: { name: 'Jane', task: { title: 'Task' } }
```
