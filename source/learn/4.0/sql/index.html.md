---
chapter: SQL
sections:
  - relations
  - schemas
  - queries
  - attributes
  - associations
  - joins
  - transactions
  - migrations
  - commands
---

ROM supports SQL databases via `rom-sql` adapter which currently uses
[Sequel](http://sequel.jeremyevans.net/) under the hood. The adapter ships with
an enhanced `Relation` that supports sql-specific query DSL and association
macros that simplify constructing joins.

Refer to the [Getting Started](/learn/%{version}/getting-started/) and
[Explicit Setup](/learn/%{version}/advanced/explicit-setup/) pages for information on
how to setup ROM with a specific adapter.

Following connection URI schemes are supported:

- `ado`
- `amalgalite`
- `cubrid`
- `db2`
- `dbi`
- `do`
- `fdbsql`
- `firebird`
- `ibmdb`
- `informix`
- `jdbc`
- `mysql`
- `mysql2`
- `odbc`
- `openbase`
- `oracle`
- `postgres`
- `sqlanywhere`
- `sqlite`
- `swift`
- `tinytds`

For details on specifying database connection URLs please refer to the
[Connecting to a database](http://sequel.jeremyevans.net/rdoc/files/doc/opening_databases_rdoc.html)
Sequel page.
