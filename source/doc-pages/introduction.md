### What is ROM?

ROM is an experimental Ruby library that aims to bring powerful object mapping
capabilities and give you back the full power of your database. It is based on a
couple of core concepts which makes it different from a typical ORM:

* Querying a database is considered as a private implementation detail
* Abstract query interfaces are evil and a source of unnecessary complexity
* Reading and mutating data are 2 distinct concerns and should be treated separately
* It must be simple to use the full power of your database

With that in mind ROM ships with [**adapters**](/introduction/adapters) that allow you to connect to any
database and exposes a DSL to define [**relations**](/introduction/relations), [**mappers**](/introduction/mappers) and [**commands**](/introduction/commands)
to simplify accessing and changing the data.

### It looks weird

ROM is a ruby library which is not implemented in a "classical way". One of the
goals of the project is to provide a minimum infrastructure to handle persistence
and mapping without messing too much with your runtime environment.

It looks weird because there's no "base" class you inherit from, there are no
modules you should include...it's just a DSL where you define relations, mappers
and commands giving you back a registry of everything you defined. That is all.
It's simple. The only constant that you reference in your code is `ROM`. Avoiding
class and module constants lowers coupling and removes a whole layer of
complexity which is class-orientation.

ROM is designed in a way that it's easy and highly recommended to use its objects
as dependencies of your objects. The interfaces are as simple as possible. The
biggest complexity lies in relations and how queries are constructed but since
you are forced to always hide those details, your application layer will never
be coupled to lower level details related to persistence.
