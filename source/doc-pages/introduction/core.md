The core of ROM is divided up into four high-level concerns:

### [**Adapters**](/introduction/adapters)
ROM uses adapters to connect to different data sources (a database, a csv file -
it doesn't matter) and exposes a native CRUD interface to its relations.

### [**Relations**](/introduction/relations)
A relation is defined as a set of tuples identified by unique pairs of attributes
and their values. In ROM it is an object that responds to `#each` which yields hashes. It
is backed by <mark>a dataset object</mark> provided by the adapter although
there's no coupling between adapters and relations.

### [**Mappers**](/introduction/mappers)
A mapper is an object that takes a tuple and turns it into a domain object. ROM
provides a DSL to define mappers and it can be integrated with 3rd-party mapping
libraries.

### [**Commands**](/introduction/commands)
Commands in ROM are intended to safely persist data. Commands can create, update and
delete data.
