# Roadmap (draft)

This page describes what we want to achieve in the first version of ROM. Please note that most of the described functionality is already done however some parts need to be refactored or slightly improved.

The plan is to finalize the described features and release an early version of ROM and then continue releasing new versions after short iterations with smaller refactors and bug fixes. Early user feedback will be highly appreciated.

ROM consists of four pieces: axiom (relational abstraction), rom (db interface), rom-mapper and rom-session. Database specific support is done through axiom adapters.

## New SQL generator ([axiom-sql-generator](https://github.com/dkubb/axiom-sql-generator) + [sql](https://github.com/dkubb/sql))

Main goal: complete refactor with an extraction of SQL generator itself so that axiom-sql-generator is only an integration between an abstract sql generator and axiom relations.

Key features:

* Generates valid SQL even from very complex relations
* Ability to collapse complex queries into simpler form
* Support for all types of joins

## Database interface ([rom](https://github.com/rom-rb/rom))

Main goal: having a very thin wrapper around axiom relations with injectable mappers that can load axiom tuples into ruby objects and dump ruby objects back into axiom tuples. ROM provides higher-level CRUD interface on top of axiom relations. Relations are represented internally as a directed graph that you setup via a simple DSL where you define attribute mappings, associations, constraints etc.

Key features:

* Exposes create/read/update/delete interface on top of axiom relations
* Exposes interface for Session

## Mapper ([rom-mapper](https://github.com/rom-rb/rom-mapper))

Main goal: extract needed functionality from current rom's codebase. Have a generic mapping interface to be able to load and dump objects. The mapper takes a tuple returned from axiom and can turn it in any data structure or rich object depending on configuration. It can also take any data structure or object and dump it back to a tuple representation digestible by axiom.

Key features:

* Supports mapping of attributes from tuples to ruby object's attributes (not necessarily 1:1 mapping, for instance FirstName => first_name should be supported too)
* Supports loading nested tuples into ruby objects with associations, embedded values or embedded collections

## Session ([rom-session](https://github.com/rom-rb/rom-session))

Main goal: having a CRUD interface built on top of Mapper that adds Unit Of Work with dependency resolution mechanism

Key features:

* Organizes queued db operations in correct order
* Executes (flush) queued db operations
* Uses IdentityMap to reduce number of executed db read operations
* Hooks into Mapper interface to finalize in-memory objects after committing changes to the db (ie setting fks in correct moment etc.)
* Unit of Work is injectable so that we can have various strategies for different dbs
