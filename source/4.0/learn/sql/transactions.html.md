---
chapter: SQL
title: Transactions
---

To use a transaction simply wrap calling a command inside its transaction block:

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

# rollback happens when any error is raised ie a CommandError from a validator
command.transaction do
  command.call
end

# manual rollback
create_user.transaction do
  user = create_user.call(name: 'Jane')

  if all_good?
    task = create_task.with(title: 'Jane').call(user)
  else
    raise ROM::SQL::Rollback
  end
end
```
