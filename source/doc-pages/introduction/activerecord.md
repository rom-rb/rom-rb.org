Many Rubyists start their journey being exposed to Rails and its favored
object relational mapping (ORM) library, `ActiveRecord`. `ActiveRecord` is an
implementation of the **Active Record** pattern. In this pattern, objects carry
the data *and* the behavior that operates on that data.

### Data Access
**Active Record**: Data access logic is part of the object and controls all
reading and writing to the database. You use the same objects to create, read,
update, and delete data. These objects are the models in traditional Rails
applications.

**ROM**: Data manipulation is handled by a separate interface with user defined
commands. Every relation that your application is going to use is explicitly
defined. The ROM relations expose powerful internal query APIs that you use to
create publicly accessible relation methods to return query results.

Imagine your `ActiveRecord` models only exposed the scopes and scope methods to
the rest of the application. This is what ROM relations are like.

### Models
**Active Record**: Models are at the heart of the pattern, and the library.
As mentioned before, all data access is via the model. The assumption is
that your application will only ever need a data representation that matches
your database exactly. As the application grows, so does the likelihood that
you need other ways to represent your data. In the Rails community this
manifests as presenters, formatters, renderers, serializers, and so on.

All those objects that you create are nothing more than mapping. They take
`ActiveRecord` objects and represent them in a context sensitive way.

**ROM**: There is no single "model" object in ROM. ROM objects that are
instantiated by the mappers have no knowledge about persistence.
