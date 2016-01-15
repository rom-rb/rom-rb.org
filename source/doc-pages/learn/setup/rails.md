# Rails Setup

Rails integration is provided by [rom-rails](https://github.com/rom-rb/rom-rails)
project. Simply add it to your Gemfile:

``` ruby
gem 'rom-rails'
```

## Configuring Railtie

Create a rom initializer:

``` ruby
# config/initializers/rom.rb
ROM::Rails::Railtie.configure do |config|
  config.gateways[:default] = [:sql, ENV.fetch('DATABASE_URL')]
end
```

You can provide additional adapter-specific options, in example you can enable
specific sql plugins for postgres:

``` ruby
# config/initializers/rom.rb
ROM::Rails::Railtie.configure do |config|
  config.gateways[:default] = [:sql,
    ENV.fetch('DATABASE_URL'), extensions: [:pg_hstore]
  ]
end
```

You can also provide a list of relations that should not be inferred from your
schema automatically:

``` ruby
# config/initializers/rom.rb
ROM::Rails::Railtie.configure do |config|
  config.gateways[:default] = [:sql,
    ENV.fetch('DATABASE_URL'), not_inferrable_relations: [:schema_migrations]
  ]
end
```

## Migration Tasks

The railtie provides rake tasks for managing your database schema. You need to
enable them in your `Rakefile`:

``` ruby
require 'rom/sql/rake_task'
```

After that, you have access to following tasks:

* `rake db:create_migration[migration_name]` - creates a new migration file
* `rake db:migrate` - runs pending migrations
* `rake db:clean` - cleans the database
* `rake db:reset` - drops tables and re-runs migrations

## Accessing Container

In Rails environment ROM container is accessible via `ROM.container`:

``` ruby
ROM.container # returns the container
```

Accessing global container directly is considered as a bad practice. The recommended
way is to use a DI mechanism to inject specific ROM components as dependencies
into your objects.

In example you can use [dry-container](https://github.com/dryrb/dry-container)
and [dry-auto_inject](https://github.com/dryrb/dry-auto_inject) gems to define
your own application container and specify dependencies there and have them
automatically injected.

See [rom-rails-skeleton](https://github.com/solnic/rom-rails-skeleton) for an example
of such setup.

## Defining Relations

Relation class definitions are being automatically loaded from `app/relations`.
In example let's define `users` relation:

``` ruby
class Users < ROM::Relation[:sql]
  # some methods
end

# access registered relation via container
ROM.container.relations[:users]
```

## Defining Commands

Command class definitions are being automatically loaded from `app/commands`.
In example let's define a command which inserts data into `users` relation:

``` ruby
# app/commands/create_user.rb
class CreateUser < ROM::Commands::Create[:sql]
  relation :users
  register_as :create
  result :one
end

# access registered relation via container
ROM.container.commands[:users][:create]
```

## Defining Custom Mappers

If you want to use custom mappers you can place them under `app/mappers`:

``` ruby
# app/commands/user_mapper.rb
class UserMapper < ROM::Mapper
  relation :users

  # some mapping logic
end
```
