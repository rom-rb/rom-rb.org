---
chapter: Introduction
title: Overview
---

ROM encourages a clear separation between your application domain and the data
access layer. This is more than just hiding access behind methods. Your
application is not coupled to the details of data retrieval or manipulation.

The figure below represents the data flow through an application using ROM:

TODO: create a new diagram :)

### Reading

1. Your application requests data from a <mark>Repository</mark>
2. Data is read from the <mark>Datastore</mark> using a <mark>Relation</mark> provided by an <mark>Adapter</mark>
3. The result is returned to your application
  * It can be optionally mapped to a different representation using <mark>Mappers</mark>

### Writing

1. Your application calls a <mark>Command</mark> to perform a Create, Update,
   Delete, or a custom operation
2. The command executes a datastore-specific operation via its relation
3. The result is returned to your application
  * It can be optionally mapped to a different representation using <mark>Mappers</mark>

#### Repositories

Repositories provide a powerful CRUD interface built on top of relation, mapping
and command APIs. They give you a simple way for composing data provided by relations,
automatically map data to struct objects or custom object types, and expose simple
access to commands with support for changesets.

#### Relations

A relation is defined as a set of tuples identified by unique pairs of
attributes and their values. In ROM it is an object that responds to `#each`
which yields hashes. It is backed by <mark>a dataset object</mark> provided by
the adapter.

#### Commands

Commands in ROM are intended to safely modify data. Commands can be used to
create, update and delete. They are usually provided by the adapter, but you may
define your own.

#### Mappers

A mapper is an object that takes a relation and maps it into a different
representation. Mappers are generated automatically by repositories and in typical
cases you don't have to define them; however, ROM provides a DSL to define custom
mappings or you can register your own mapper objects for custom, non-standard
queries, or complex cross-datastore mappings.

#### Adapters

ROM uses adapters to connect to different data sources (a database, a csv file -
it doesn't matter) and exposes a native CRUD interface to its relations. Every
adapter has extension points to support database-specific functionality. It provides
its own relation types, extensions for built-in commands, and potentially new command
types. Furthermore, an adapter can provide extra features that are needed to work
with a given database type. For example, `rom-sql` provides Migration API.

