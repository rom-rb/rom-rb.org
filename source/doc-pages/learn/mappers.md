Every application needs different representations of the same data. Taking
data from one representation and converting it into another is done by using
mappers in ROM.

A mapper is an object that takes a tuple and turns it into a domain object.

ROM provides a DSL to define mappers which can be integrated with 3rd-party
libraries.

By defining a mapper you are specifying which entity class is going to be
instantiated and what attributes are going to be used. Entity classes can be
flat objects or aggregates and these definitions can be created for every
relation separately if that's what you need.

This flexibility can simplify your domain layer quite a bit. You can design
your domain objects exactly the way you want and configure mappings
accordingly. Mapping is an extremely powerful concept. It can:

* Rename attributes
* Coerce values
* Build aggregate objects
* Build immutable value objects

ROM also allows you to define mappers that can be reused for many relations.

Relations and mappers are a very powerful combination for reading data. To
change data ROM uses [Commands](/introduction/commands).
