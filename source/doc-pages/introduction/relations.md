A relation is defined as a set of tuples identified by unique pairs of attributes
and their values. In Ruby the simplest, efficient and convenient way of
representing this is an array of hashes.

In ROM a relation is an object that responds to `#each` which yields hashes. It
is backed by <mark>a dataset object</mark> provided by the adapter although
there's no coupling between adapters and relations. You can instantiate a
relation yourself and pass in an array of hashes and that's it.

ROM relations provide additional functionality on top of adapter datasets that
can be summarized as:

* every relation has <mark>a header</mark> with tuple attribute names
* a relation can be extended with adapter-specific interfaces
* relations from different data sources can be combined together in memory

It is a lightweight layer that gives you a lot of flexibility when it comes to
fetching data and building complex queries but there's also one important reason
why it exists:

> Relations encapsulate application data access

It means that every detail about how data is being retrieved from data sources
is hidden in the relation layer. Your application only sees the relations, it
doesn't care about the underlaying databases, queries, column names and whatnot.

That's why:

> Relations are a solid convention for organizing data access in your application

Please notice that relation layer is very lightweight. ROM builds relation
objects based on the schema and extends them with adapter-specific functionality.
Thanks to that adapters can provide additional behavior which is powerful and
it doesn't require more objects than the relations themselves.

As a nice side-effect you can easily see how your application uses the
database by simply inspecting all of the defined relations.

Relations, however, only provides tuples (reminder: hashes) which typically is
not very convenient. In complex domains we want richer, domain-specific objects.
That's why ROM has [a mapping layer](/introduction/mappers).
