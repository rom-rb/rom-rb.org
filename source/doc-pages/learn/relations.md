Relational theory defines relations as a set of tuples identified by unique
pairs of attributes and their values. In Ruby, it's easiest to think of this
as an array of hashes.

A ROM relation is an object that responds to `#each` and yields hashes. It is
typically backed by a <mark>dataset object</mark> provided by the adapter,
though there's no coupling between adapters and relations. You could
instantiate a relation yourself and pass in an array of hashes.

**Relations provide a way to encapsulate *and* organize application data
access in your application.**

Every detail about how data is being retrieved from data sources is
contained in the relation layer. Your application sees only the relations, it
doesn't have to care about the databases, queries, column names, limits, etc.

A relation is a lightweight layer that gives you a lot of flexibility when it
comes to fetching data and building complex queries. ROM builds relation
objects based on the schema and extends them with adapter-specific
functionality. _(This feature is already used by `rom-sql` to extend
Sequel's dataset API with convenient methods for joining relations.)_

In fact, ROM relations provide:

* <mark>a header</mark> with tuple attribute names
* extension methods for adapter interfaces
* ways to combine data from different sources in memory

By using this lightweight style, ROM is able to provide powerful data access
without a myriad of intermediate objects.

As flexible as they are, relations only provide the data in tuples which is not
always convenient for your application. In complex domains we want rich domain
specific objects. That's why ROM has [a mapping layer](/introduction/mappers).
