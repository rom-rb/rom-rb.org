# Active Record and ROM

This document explains basic differences between Active Record ORM from Rails and
ROM.

### Database Support

**Active Record**: supports only SQL

**ROM**: supports anything that can provide data, including SQL databases, NoSQL
databases, CSV files, git repositories, remote HTTP APIs, anything. You can work
with multiple databases at once and combine data in memory, if that's what you need.

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
instantiated by the mappers have no knowledge about persistence. You can map to
whatever structure you want and in common use-cases you can use repositories to
automatically map query results to simple struct-like objects.

### Validation

**Active Record**: mixes domain-specific data validation with persistence layer.
An active record object validates itself using its own validation rules.

**ROM**: there's no validation concept built-in. Validations are handled externally
by separate libraries and validated data can be passed down to the command layer
to be persisted. Currently `rom-model` gem provides a standalone validation layer.

### Data Coercion

**Active Record**: handles coercion internally prior persisting data

**ROM**: input should be coerced by an external component. Currently `rom-model`
provides a standalone input coercion layer.
