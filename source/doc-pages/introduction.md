Ruby Object Mapper (ROM) is an experimental Ruby library with the goal to
provide powerful object mapping capabilities without limiting the full power
of your datastore. ROM is based on several concepts and decisions that
differentiate it from your normal Ruby ORM:

* Be kind to the runtime environment
* Provide minimum infrastructure to handle mapping and persistence
* Querying the datastore is considered a private implementation detail
* Abstract query interfaces are sources of unnecessary complexity
* Reading and mutating data are distinct concerns
* Simple to use the underlying datastore when desired

These [core concepts](/introduction/overview) are implemented in ROM with
[**adapters**](/introduction/adapters), [**relations**](/introduction/relations),
[**mappers**](/introduction/mappers), and [**commands**](/introduction/commands).

### ROM code looks weird

ROM is not implemented in the typical Ruby fashion. As mentioned above, ROM
provides minimum infrastructure to accomplish its goals. The code in
ROM looks weird because there are no "base" classes to inherit from and no
modules to include. Avoiding the typical class-orientation and module constants
lowers coupling and removes layers of complexity.

ROM is a DSL used to define relations, mappers, and commands, giving you back
a registry of everything you defined. The only constant you reference in your
code is `ROM`.
