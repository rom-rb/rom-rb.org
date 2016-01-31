---
title: Block Style Setup
chapter: Setup
---

# Block Style

This guide explains how to configure ROM using block style which is suitable for
simple scripts.

If you're using ROM with a framework, see specific instructions in the setup
section.

## Connect to a Gateway

Call `ROM#container` with the adapter symbol and configuration details for that
adapter:

```ruby
# This creates a rom-sql adapter backed by SQLite in-memory database
ROM.container(:sql, 'sqlite::memory') do |rom|
    # define relations and commands here...
end

# ROM also comes with a very barebones in-memory adapter.
ROM.container(:memory, 'memory://test') do |rom|
    # define relations and commands here...
end
```

### &hellip;Or Several

Sometimes you have multiple data sources. You can provide multiple
[gateway](/learn/glossary/#gateway) configurations with a name
hash.

```ruby
# Example: an old mysql database, “tasks”, and a new database “task_master”
# This registers two rom-sql adapters and then labels postgres with “default” and mysql with “legacy”
ROM.container(
  default: [:sql, 'postgres://localhost/task_master'], # gateway 1
  legacy: [:sql, 'mysql2://localhost/tasks']           # gateway 2
) do |rom|
    # setup code goes here...
end
```

If there is only one adapter provided, then its label is assumed to be
`:default`:

```ruby
# This setup call...
ROM.container(:sql, 'sqlite::memory')

# is equivalent to this one:
ROM.container(default: [:sql, 'sqlite::memory'])
```

## Access the Environment Container

`ROM.container` always returns the finalized environment container, which can
then be injected into your domain logic as a dependency.

```ruby
rom_container = ROM.container(:sql, 'sqlite::memory') do |rom|
    # define relations and commands here...
end

# now pass it to your app and rejoice!
MyApp.run(rom_container)
```

> ActiveRecord and DataMapper provide a global access to data, but this is
> considered a bad practice in modern standards.
>
> Injecting the container keeps your app free from persistence details and more
> flexible for testing.

## Plugins

Both block and flat style support calling `use` on the `ROM::Configuration`
object to activate plugins for that configuration.

Currently, the only bundled plugin is `:macros`, which provides the DSL for
specifying your relations, commands, and mappers.

```ruby
ROM.container(:sql, 'sqlite::memory') do |rom|
   # rom is a ROM::Configuration
   rom.use :macros
end
```

## Next

Learn [how to read](/learn/read/) by defining Repositories and Relations
