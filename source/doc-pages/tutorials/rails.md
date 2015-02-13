This tutorial explains how to make ROM feel right at home in your Rails application. It is primarily intended for those familiar with Rails who want to learn more about ROM.

To understand the core concepts behind ROM, we will work through the steps required to build
a simple task management application.

### Contents

* [Getting started](/tutorials/rails/getting-started) - quickly initialize an application with a ROM-based template
* [Tasks index](/tutorials/rails/tasks-index) - display a list of tasks using a generated relation
* [Task relation](/tutorials/rails/task-relation) - extend the tasks relation to order results
* [Task mapper](/tutorials/rails/task-mapper) - define a dedicated mapper for domain objects
* [Managing tasks](/tutorials/rails/managing-tasks) - implement create/update/delete actions with commands
* [Validations](/tutorials/rails/validations) - use validators

The following libraries are used throughout:

* [rom](https://github.com/rom-rb/rom) - main gem for the ROM project
* [rom-sql](https://github.com/rom-rb/rom-sql) - database adapter based on [Sequel](https://github.com/jeremyevans/sequel)
* [rom-rails](https://github.com/rom-rb/rom-rails) - Rails integration for ROM

Of note is the [rom-rails](https://github.com/rom-rb/rom-rails) library, which
is essentially a Railtie and some generators. The Railtie allows you to place
[relations](/introduction/relations), [mappers](/introduction/mappers), and
[commands](/introduction/commands) in directories similar to how Rails
places models, controllers, and mailers under the `app` directory. 
