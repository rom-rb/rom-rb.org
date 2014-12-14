This is a small series of introductory articles that explain ROM architecture
and reasons for the existance of this project. It is divided into 4 sections
each explaining the core parts of ROM.

### What is ROM?

ROM is an experimental Ruby library that aims to bring powerful object mapping
capabilities and give you back the full power of your database. It is based on a
couple of core concepts which makes it different from a typical ORM:

* Querying a database is considered as a private implementation detail
* Abstract query interfaces are evil and a source of unnecessary complexity
* Reading and mutating data are 2 distinct concerns and should be treated separately
* It must be simple to use the full power of your database

With that in mind ROM ships with adapters that allow you to connect to any
database and exposes a DSL to define **relations**, **mappers** and **commands**
to simplify accessing and changing the data.

### Architecture overview

When using ROM you clearly separate data access layer exposed by relations from
your application layer. This means your application code is not coupled with the
details about how the data are being fetched or where it's being fetched from.

Furthermore you can (and in most of the cases you want to) use mapping layer to
map relation tuples into richer domain objects.

Changing the data is treated separately via commands that have access to the
defined relations and integrate with 3rd party data sanitization and validation
libraries.

Here's a simple diagram showing the architecture:

<p class="text-center">
  <img src="/images/rom-design-overview.png"/>
</p>

### Differences between ROM and ActiveRecord

For starters - ROM doesn't implement the Active Record pattern. This means that
objects instantiated by the mappers have no knowledge about persistence. ROM
favors explicit definitions of every relation that your application is going to
use as opposed to dynamic retrieval of active records using a wide query api.
ROM relations expose a powerful query APIs that you can use internally to expose
publicly acessible relations which are results of those queries.

You can say that relations in ROM are like ActiveRecord relations where the only
public methods are the ones you defined as "scopes". It's a subtle but significant
difference.

Another difference is how data manipulation is handled. In case of ActiveRecord
you use the same objects to read as well as create, update and delete data. In
ROM data manipulation is handled by a separate interface using commands that
you define. It's a simple infrastructure that helps in a structured and explicit
approach to data manipulation which requires special care.

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

### Why would I want to use it?

If you care about clarity, explicitness and structured approach to handling data
and persistence you probably want to give ROM a try. With ROM you design your
domain layer like you want, it's not coupled to the structure of your database.
It also makes it easy to work with different datasources by giving you a minimum
infrastructure to support it. It avoids high-level abstractions that are great
in the beginning and a horror later on. Its adapters are based on battle-tested
and powerful libraries like `Sequel` giving you a very stable foundation. It can
be easily integrated with full-stack frameworks like Rails or used "standalone"
in other use cases. Oh, it's fast too and highly optimizable.
