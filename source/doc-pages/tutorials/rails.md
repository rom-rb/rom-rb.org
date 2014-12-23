Welcome to the ROM on Rails tutorial.

This tutorial will help to explain some of the basic concepts behind ROM
by building a simple Rails application to manage tasks. You will extend
[relations](/introduction/relations), define [mappers](/introduction/mappers),
and use [commands](/introduction/commands) to modify data. It is primarily
intended for those familiar with Rails who want to learn more about ROM.

* [Getting started](/tutorials/rails/getting-started) - quickly initialize an application with a ROM-based template
* [Tasks index](/tutorials/rails/tasks-index) - display a list of tasks using a generated relation
* [Task mapper](/tutorials/rails/task-mapper) - extend the tasks relation and define a dedicated mapper
* [Managing tasks](/tutorials/rails/managing-tasks) - implement create/update/delete actions with commands
* [Validations](/tutorials/validations) - use validators

The following libraries are used throughout:

* [rom](https://github.com/rom-rb/rom) - main gem for the ROM project
* [rom-sql](https://github.com/rom-rb/rom-sql) - database adapter based on [Sequel](https://github.com/jeremyevans/sequel)
* [rom-rails](https://github.com/rom-rb/rom-rails) - Rails integration for ROM

Of note is the [rom-rails](https://github.com/rom-rb/rom-rails) library, which
is essentially a Railtie and some generators. The Railtie allows you to place
[relations](/introduction/relations), [mappers](/introduction/mappers), and
[commands](/introduction/commands) in directories similar to how Rails
places models, controllers, and mailers under the `app` directory. The
integration makes ROM feel right at home in youru Rails application.
