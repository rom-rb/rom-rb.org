---
chapter: SQL Adapter
title: Migrations
---

The SQL adapter uses Sequel migration API exposed by SQL gateways. You can either
use the built-in rake tasks, or handle migrations manually.

## Migration Rake Tasks

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

The following tasks are available:

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
