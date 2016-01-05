ROM encourages a clear separation between your application domain and the data
access layer. This is more than just hiding access behind methods. Your
application is not coupled to the details of data retrieval or manipulation.

The figure below represents how data flows through an application using ROM:

The data flows from the <mark>datastore</mark>, through the
<mark>adapter</mark>, to be accessed by <mark>relations</mark>, and then
optionally mapped to domain objects by <mark>mappers</mark>. Modifying data
requires the use of <mark>commands</mark> that use the <mark>adapter</mark>
to persist changes.

<img src="/images/rom-design-overview.png"/>

#### [**Adapters**](/introduction/adapters)

ROM uses adapters to connect to different data sources (a database, a csv file -
it doesn't matter) and exposes a native CRUD interface to its relations.

#### Repositories

A repository provides a convenient interface for fetching domain-specific entities
and value objects from a database. It's a higher-level abstraction built on top
of relation and mapping layers.

#### Relations

A relation is defined as a set of tuples identified by unique pairs of attributes
and their values. In ROM it is an object that responds to `#each` which yields hashes. It
is backed by <mark>a dataset object</mark> provided by the adapter.

#### Mappers

A mapper is an object that takes a relation and maps it into a different representation.
ROM provides a DSL to define mappers or you can register your own mapper objects.

#### Commands

Commands in ROM are intended to safely modify data. Commands can be used to create,
update and delete.

##Next
Continue on to read about [Setup](/guides/basics/setup)
