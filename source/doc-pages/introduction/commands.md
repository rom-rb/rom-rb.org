Changing data is probably one of the most complex and risky things an application
does. It needs special care and attention to deal with raw input received at the
boundaries of our application. We need to sanitize, often coerce and validate
that input and decide what to do with it.

This can, in fact, be so complex that having it handled on the same layer where
data access happens is not reasonable. ROM follows the idea of [CQRS](http://martinfowler.com/bliki/CQRS.html)
which may sound overly complicated but it's really a simple concept - querying
data is separated from changing the data.

It's the most experimental part of ROM; however, it is based on what many of us
in the Rails community have been doing for years. Let's talk about form objects.

Using form objects turned out to be a very useful and common pattern. There are
even many libraries that makes it easy to use it. It might be surprising but
a form object is simply an object that receives an input, validates it and saves
it in the database. It is a command object that has one purpose - to safely
persist data.

ROM expands this idea to be more abstract - commands can create, update and
delete data and it doesn't really matter where the input is coming from.

Here are main goals of the command api:

* have an explicit way to define how you change your data
* have a convention for dealing with the input
* make error handling simple
* have an ability to levarage database features to ensure data integrity

The last goal is probably the most crucial one - quite often our database is our
best friend to make sure our data are in tact. Many SQL databases support setting
constraints like "not-null", or "unique" on specific columns. We can and should
levarage those features. This has been a known fact in the Rails community for
years but let's remind ourselves that in the beginning lack of those constraints
was typical and relying only on ActiveRecords validations was a common problem.

For those reasons ROM has command api built in - you can inject your own input
handlers and validators for every command and use them in your application.

Every adapter implements commands on its own that's why we can support
database-specific features too. For instance `rom-sql` can handle database
constraint errors gracefully and return them wrapped by a failure object to your
application layer where you can decide what to do with it.
