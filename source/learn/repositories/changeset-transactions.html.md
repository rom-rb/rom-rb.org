---
chapter: Repositories
title: Changeset Transactions
---

If you want to commit multiple changesets, it's a good idea to wrap that operation in a
repository transaction. Changesets can be associated with each other using `Changeset#associate`
method, which will automatically set foreign keys for you, based on schema associations.

Let's define `:users` relation that has many `:tasks`:

``` ruby
require 'rom'

rom = ROM.container(:sql, 'sqlite::memory') do |conf|
  conf.default.create_table(:users) do
    primary_key :id
    column :name, String, null: false
  end

  conf.default.create_table(:tasks) do
    primary_key :id
    foreign_key :user_id, :users, null :false
    column :title, String, null: false
  end

  conf.relation(:users) do
    schema(infer: true) do
      associations do
        has_many :tasks
      end
    end
  end

  conf.relation(:tasks) do
    schema(infer: true) do
      associations do
        belongs_to :user
      end
    end
  end
end
```

With associations established in the schema, we can easily associate data using changesets and commit
them in a transaction:

``` ruby
class UserRepo < ROM::Repository[:users]
  commands :create
end

class TaskRepo < ROM::Repository[:tasks]
  commands :create
end

task_repo = TaskRepo.new(rom)
user_repo = UserRepo.new(rom)

task = task_repo.transaction do
  user = user_repo.create(name: 'Jane')

  new_task = task_repo.changeset(title: 'Task One').associate(user, :users)

  task_repo.create(new_task)
end

task
# #<ROM::Struct[Task] id=1 user_id=1 title="Task One">
```

## Learn more

* [api::rom-repository::Repository](#transaction)
