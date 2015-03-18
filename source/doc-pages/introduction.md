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

### ROM philosophy

ROM is not implemented in the typical Ruby fashion. As mentioned above, ROM provides minimum infrastructure to accomplish its goals, it is designed with ease-of-use in mind - so although the convenience class methods you usually see in Rubyland are avoided, classes are instantiated for you, and can be accessed via the ROM environment, this means that the only class that you need to interface with is ROM and simple dependency-injection is encouraged.


All ROM components are built to be stand-alone, they can be used independently of each other, are loosely coupled and follow the single responsibility principle, rather than having a single object that handles coercion, state, persistence, validation and your all-important business logic, ROM provides the infrastructure to allow you to easily create small dedicated classes for handling each of these concerns individually, and tie it all together in a simple, manageable fashion.
