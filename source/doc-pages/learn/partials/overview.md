ROM encourages a clear separation between your application domain and the data
access layer. This is more than just hiding access behind methods. Your
application is not coupled to the details of data retrieval or manipulation.

The figure below represents the data flow through an application using ROM:

<img src="/images/rom-design-overview.png"/>

**Reading**

1. Your application requests data from a <mark>Relation</mark> (or its easier cousin <mark>Repository</mark>)
1. Data is read from the <mark>Datastore</mark> using the <mark>Adapter</mark>
1. The result is returned to your application
   * It can also optionally be mapped to domain objects using <mark>Mappers</mark>
   
**Writing**

1. Your application calls a <mark>Command</mark> to perform a Create, Update, Delete, or custom operation
1. The command runs using its underlying Relation and Adapter to modify the datastore 
1. The result is returned to your application


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
update and delete. They are usually provided by the adapter, but you may define your own. 

##Next
Continue on to read about [Setup](/learn/basics/setup)
