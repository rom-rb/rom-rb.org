ROM encourages a clear separation between your application domain and the data
access layer. This is more than just hiding access behind methods. Your
application is not coupled to the details of data retrieval or manipulation.

The figure below represents how data flows through an application using ROM:

The data flows from the <mark>database/datastore</mark>, through the
<mark>adapter</mark>, to be accessed by <mark>relations</mark>, and then
optionally mapped to domain objects by <mark>mappers</mark>. Modifying data
requires the use of <mark>commands</mark> that use the <mark>adapter</mark>
to persist changes.

<img src="/images/rom-design-overview.png"/>

The core of ROM is divided up into four high-level concerns as you can see
above:

### [**Adapters**](/introduction/adapters)
ROM uses adapters to connect to different data sources (a database, a csv file -
it doesn't matter) and exposes a native CRUD interface to its relations.

### [**Relations**](/introduction/relations)
A relation is defined as a set of tuples identified by unique pairs of attributes
and their values. In ROM it is an object that responds to `#each` which yields hashes. It
is backed by <mark>a dataset object</mark> provided by the adapter.

### [**Mappers**](/introduction/mappers)
A mapper is an object that takes a tuple and turns it into a domain object. ROM
provides a DSL to define mappers which can be integrated with 3rd-party mapping
libraries.

### [**Commands**](/introduction/commands)
Commands in ROM are intended to safely modify data. Commands can be used to create,
update and delete.
