---
chapter: Getting Started
title: Setup DSL
---

This guide explains how to quickly configure ROM using setup DSL, which is suitable for
simple scripts.

> #### ROM & frameworks
>
> If want to use ROM with a framework, see specific instructions in the getting
> started section.

> #### Configuration
>
> The configuration options explained in this document are the same for
> [Explicit Setup](/%{version}/learn/advanced/explicit-setup) using `ROM::Configuration` object

## Connect to a single database

Call `ROM.container` with the adapter symbol and configuration details for that
adapter:

```ruby
# This creates a rom-sql adapter backed by SQLite in-memory database
ROM.container(:sql, 'sqlite::memory') do |config|
  # define relations and commands here...
end

# when using SQLite with a file be sure to use the file's full path
rom = ROM.container(:sql, 'sqlite:///Users/you/full/path/test.db') do |config|
  # define relations and commands here...
end

# You can provide additional connection options too
ROM.container(:sql, 'postgres://localhost/my_db', extensions: [:pg_json]) do |config|
  # define relations and commands here...
end

# ROM also comes with a very barebones in-memory adapter.
ROM.container(:memory, 'memory://test') do |config|
  # define relations and commands here...
end
```

### Connect to multiple databases

Sometimes you have multiple data sources. You can provide multiple
[gateway](/%{version}/learn/glossary/#gateway) configurations with a name
hash.

```ruby
# Example: an old mysql database, “tasks”, and a new database “task_master”
# This registers two rom-sql adapters and then labels postgres with “default” and mysql with “legacy”
ROM.container(
  default: [:sql, 'postgres://localhost/task_master'], # gateway 1
  legacy: [:sql, 'mysql2://localhost/tasks']           # gateway 2
) do |config|
    # setup code goes here...
end
```

If there is only one adapter provided, then its identifier is automatically set
to `:default`:

```ruby
# This setup call...
ROM.container(:sql, 'sqlite::memory')

# is equivalent to this one:
ROM.container(default: [:sql, 'sqlite::memory'])
```

## Access the container

`ROM.container` always returns the finalized environment container **object**.
This object is not global, and it must be managed either by you or a framework
that you use.

```ruby
rom = ROM.container(:sql, 'sqlite::memory') do |config|
  # define relations and commands here...
end
```

> ActiveRecord and DataMapper provide global access to their components, but this
> is considered a bad practice in modern standards. ROM creates an isolated, local
> container without polluting global namespaces. This allows you to easily pass
> it around without being worried about accidental side-effects like conflicting
> database connections or configurations being overridden in a non-thread-safe
> way

## Next

Learn [how to read data](/%{version}/learn/repositories/reading-simple-objects/) via Repositories and Relations.
