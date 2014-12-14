### Differences between ROM and ActiveRecord

For starters - ROM doesn't implement the Active Record pattern. This means that
objects instantiated by the mappers have no knowledge about persistence. ROM
favors explicit definitions of every relation that your application is going to
use as opposed to dynamic retrieval of active records using a wide query api.
ROM relations expose a powerful query APIs that you can use internally to expose
publicly acessible relations which are results of those queries.

You can say that relations in ROM are like ActiveRecord relations where the only
public methods are the ones you defined as "scopes". It's a subtle but significant
difference.

Another difference is how data manipulation is handled. In case of ActiveRecord
you use the same objects to read as well as create, update and delete data. In
ROM data manipulation is handled by a separate interface using commands that
you define. It's a simple infrastructure that helps in a structured and explicit
approach to data manipulation which requires special care.
