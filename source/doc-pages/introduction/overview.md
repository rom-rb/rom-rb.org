### Architecture overview

When using ROM you clearly separate data access layer exposed by relations from
your application layer. This means your application code is not coupled with the
details about how the data are being fetched or where it's being fetched from.

Furthermore you can (and in most of the cases you want to) use mapping layer to
map relation tuples into richer domain objects.

Changing the data is treated separately via commands that have access to the
defined relations and integrate with 3rd party data sanitization and validation
libraries.

Here's a simple diagram showing the architecture:

<p class="text-center">
  <img src="/images/rom-design-overview.png"/>
</p>
