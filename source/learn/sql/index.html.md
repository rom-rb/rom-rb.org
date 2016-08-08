---
chapter: SQL
sections:
  - relations
  - schemas
  - associations
  - joins
  - commands
  - transactions
  - migrations
---

ROM supports SQL databases via `rom-sql` adapter which currently uses
[Sequel](http://sequel.jeremyevans.net/) under the hood. The adapter ships with
an enhanced `Relation` that supports sql-specific query DSL and association
macros that simplify constructing joins.

Refer to the general [setup](/learn/getting-started/block-style-setup) for information
how to setup rom- with a specific adapter.

Following connection URI schemes are supported:

- ado
- amalgalite
- cubrid
- db2
- dbi
- do
- fdbsql
- firebird
- ibmdb
- informix
- jdbc
- mysql
- mysql2
- odbc
- openbase
- oracle
- postgres
- sqlanywhere
- sqlite
- swift
- tinytds

## Establishing Gateways

TODO
