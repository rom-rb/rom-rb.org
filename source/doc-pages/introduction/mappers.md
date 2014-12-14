Every application needs different representations of the same data. Further more
it needs different objects to encapsulate that data. The biggest problem with
ActiveRecord approach is that it assumes, by design, that your application will
only ever want exactly what you have in your databases. This very quickly turns
out to be a false assumption. For that reason people in Rails community started
experimenting with presenters, formatters, renderers, serializers and so on to
deal with growing complexity caused by active record objects feeding your
application layer with canonical data taken directly from a database.

Fun fact about this is that all those extra objects that you create are nothing
else than mapping - those objects take active records to represent them in a way
that fits in a given context. If you display a todo item on a web site you can
create a todo-presenter. If you respond with all todo items in a json-api you
use some sort of a serializer object to turn active records into json. What
essentially happens is that you write mappers on your own!

That's the reason why mapping concept is built into ROM. We need different
representations of the same data - we need mappers.

A mapper is an object that takes a tuple and turns it into a domain object. ROM
provides a DSL to define mappers and it can be integrated with 3rd-party mapping
libraries.

When you define a mapper you specify which entity class is going to be
instantiated and what attributes are going to be used. You can specify either
"flat" objects or aggregates and you can do it for every relation separately if
that's what you need.

This gives you a lot of flexibility as <mark>you can design your domain objects
exactly like you want</mark> and then configure mappings accordingly which
simplifies your application layer a lot.

Mapping can be truly powerful as it can take care of:

* Renaming attributes
* Coercing values
* Building aggregate objects
* Building immutable value objects

Notice that every relation can be unique in terms of its header but there are
many cases where you have a restricted set of tuples that have the same header.
Defining mappers separately for each relation despite having the same header
would be tiresome and causing lots of duplication that's why ROM allows you to
define one mapper that can be reused for many relations.

Relations and mappers are a very powerful combination for reading data. This is
obviously not the end of the story - we need to be able to change data too. For
this ROM uses [Commands](/introduction/commands).
