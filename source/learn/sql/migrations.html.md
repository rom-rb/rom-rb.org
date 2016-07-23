---
title: SQL Adapter
chapter: Migrations
---

There are migration tasks available and migration interface available in SQL
gateways.

### Using Rake Tasks

To load migration tasks simply require them and provide `db:setup` task which
sets up ROM.

``` ruby
# your rakefile

require 'rom/sql/rake_task'

namespace :db do
  task :setup do
    # your ROM setup code
  end
end
```

Following tasks are available:

* `rake db:create_migration[create_users]` - create migration file under
  `db/migrations`
* `rake db:migrate` - runs migrations
* `rake db:clean` - removes all tables
* `rake db:reset` - removes all tables and re-runs migrations

### Using Gateway Migration Interface

You can use migrations using gateway's interface:

``` ruby
rom = ROM.container(:sql, 'postgres://localhost/rom')

gateway = rom.gateways[:default]

migration = gateway.migration do
  change do
    create_table :users do
      primary_key :id
      column :name, String, null: false
    end
  end
end

migration.apply(gateway.connection, :up)
```
