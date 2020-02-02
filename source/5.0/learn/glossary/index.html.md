---
chapter: Glossary
---

This document explains basic terms used in ROM.

#### Relation

An object that represents data in your system, implements `each` and yields
[tuples](#tuple).

#### Repository

An object that uses _relations_ to interact with a datastore.  A repository is a class that is used to define a clear API between your database and your application.

#### Mapper

An object that receives a relation and maps it to another representation. Anything
that responds to `call` can be a mapper in ROM.

#### Command

An object that executes a datastore-specific operation in order to create, update
or delete tuples in a relation. Commands execute operations using relation
interface which is datastore-specific; however, on the surface they simply respond
to `call`.

Every adapter *can provide custom command types*.

#### Tuple

An element in a relation. Typically represented by a hash object.

#### Datastore

A persistence backend, typically a database but also a flat file with data like
CSV or YAML.

#### Gateway

An object that encapsulates access to a specific persistence backend. For example
the SQL gateway provides access to database tables via its [datasets](#dataset)

#### Dataset

A raw source of data with an interface specific for a given datastore. Relations
use datasets to fetch data from persistence backends, like databases. Dataset's
interface is not directly exposed to the application layer; however, it is
available as private interface of relations.

#### Adapter

An adapter is a library providing infrastructure for ROM to support specific
persistence backends. An adapter ships with its own `Gateway`, `Dataset`, `Relation`
and `Command` classes.

## Patterns

ROM is implemented using a couple of fundamental patterns that make it flexible
and extendible.

#### Callable Functional Objects

Relation, mapper and command objects are callable and work as functions, they
receive input and return output with no run-time side-effects. Furthermore all
objects don't have mutable state and it's safe to memoize them and rely on
consistent behavior.

#### Data Pipeline

Relations, mappers and commands can be composed into a data pipeline which is a
simple idea that one object returns a relation and passes it to another. All objects
respond to `call` and accept a relation and implement common `>>` operator which
is used to construct the pipeline.

#### Graph

A nested object with a root and its nodes. ROM allows you to build `relation`
and `command` graphs for working with nested structures and associations.

#### CQRS

A way of organizing your application so that reading data is separated from
changing data. In ROM it is easily achievable by using relations and commands.
