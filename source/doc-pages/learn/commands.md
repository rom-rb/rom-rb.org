Commands can create, update, and delete data.

Commands are the most experimental part of ROM. They're based on the idea
of [command query responsibility segregation (CQRS)](http://martinfowler.com/bliki/CQRS.html)
-- querying data is separate from changing the data.

Changing data is probably one of the most complex and risky things an application
does. It needs special care and attention to deal with raw input received at the
boundaries of our application. We need to sanitize, often coerce and validate
that input and decide what to do with it.

The main goals of the command api are:

* an explicit way to define how you change your data
* convention for dealing with the input
* simple error handling
* ability to leverage database features to ensure data integrity

The last goal is probably the most crucial one. Many SQL databases support setting
constraints like "not-null", or "unique" on specific columns. We can and should
leverage those features.

With the command api, you can inject your own input handlers and validators for
every command. Adapters implement commands which is why we can support database
specific features. For instance, `rom-sql` can handle database constraint errors
gracefully and return them wrapped by a failure object to your application
layer.
