### Setup

To use ROM with rails simply add `rom-rails` to your Gemfile:

``` ruby
gem 'rom-rails'
```

Make sure to use the latest version

## Schema

Defining schema is only required for adapters that don't support inferring schema
automatically. This means if you're using `rom-sql` you don't have to define the schema.
In other cases the railtie expects the schema to be in `db/rom/schema.rb` which
is loaded before relations and mappers.

## Relations, mappers and commands

The railtie automatically loads relations, mappers and commands from
`app/relations`, `app/mappers` and `app/commands` and finalizes the environment
afterwards. During the booting process the DSL is available through `ROM`.

## Sample application

Coming soon :)
