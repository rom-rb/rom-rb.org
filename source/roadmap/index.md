---
title: Ruby Object Mapper - Roadmap
---
# Roadmap (draft)

This page describes what we want to achieve in the first version of ROM. Please note that most of the described functionality is already done however some parts need to be refactored or slightly improved.

The plan is to finalize the described features and release an early version of ROM and then continue releasing new versions after short iterations with smaller refactors and bug fixes. Early user feedback will be highly appreciated.

ROM consists of three pieces: relation (db interface), mapper and session. Under the hood it uses a powerful relation algebra library called [axiom](https://github.com/dkubb/axiom). Database specific support is done through axiom adapters.

<hr/>

## New SQL generator

Main goal: complete refactor with an extraction of SQL generator itself so that axiom-sql-generator is only an integration between an abstract sql generator and axiom relations.

Key features:

* Generates valid SQL even from very complex relations
* Ability to collapse complex queries into simpler form
* Support for all types of joins

Projects:

* [sql](https://github.com/dkubb/sql)
* [axiom-sql-generator](https://github.com/dkubb/axiom-sql-generator)
* [axiom-do-adapter](https://github.com/dkubb/axiom-do-adapter)

## Relation

Main goal: provide high-level CRUD interface on top of axiom relations.

Key features:

* Provides a DSL to setup relations, associations, fk constraints etc.
* Exposes create/read/update/delete interface on top of axiom relations
* Supports injectable mappers for loading data into ruby objects and dumping them back to raw tuples
* Exposes interface for Session

## Mapper

Main goal: extract needed functionality from current rom's codebase. Have a generic mapping interface to be able to load and dump objects. The mapper takes a tuple returned by axiom and can turn it into any data structure or rich object depending on configuration. It can also take any data structure or object and dump it back to a tuple representation digestible by axiom.

Key features:

* Supports mapping of attributes from tuples to ruby object's attributes (not necessarily 1:1 mapping, for instance FirstName => first_name should be supported too)
* Supports loading nested tuples into ruby objects with associations, embedded values or embedded collections

## Session

Main goal: provide a CRUD interface built on top of rom relation that adds Unit Of Work with dependency resolution mechanism and state tracking.

Key features:

* Organizes queued db operations in correct order
* Executes (flush) queued db operations
* Uses IdentityMap to reduce number of executed db read operations
* Hooks into Mapper interface to finalize in-memory objects after committing changes to the db (ie setting fks in correct moment etc.)
* Unit of Work is injectable so that we can have various strategies for different dbs
