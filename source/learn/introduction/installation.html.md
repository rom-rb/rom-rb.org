---
chapter: Introduction
title: Installation
sections:
  - core-concepts
---

Choose one or more adapters that you intend to use, and run the install command
for each one (or add it to your `Gemfile`)

Compatible with `rom 5.0`:

|Adapter|Install Command|On production?|
|-------|---------------|---|
|SQL|`gem install rom-sql`| √ |
|Elasticsearch|`gem install rom-elasticsearch`| √ |
|HTTP|`gem install rom-http`| √ |
|YAML|`gem install rom-yaml`| √ |

Compatible with `rom 4.0`:

|Adapter|Install Command|On production?|
|-------|---------------|---|
|SQL|`gem install rom-sql`| √ |
|Elasticsearch|`gem install rom-elasticsearch`| √ |

Compatible with `rom 3.0`:

|Adapter|Install Command|On production?|
|-------|---------------|---|
|YAML|`gem install rom-yaml`| √ |
|CouchDB|`gem install rom-couchdb`| √ |
|HTTP|`gem install rom-http`| √ |
|DynamoDB|`gem install rom-dynamodb`| √ |
|Yesql|`gem install rom-yesql`| √ |

Outdated (help wanted!) adapters:

|Adapter|Install Command|Production ready?
|-------|---------------|---|
|CSV|`gem install rom-csv`| √ |
|Git|`gem install rom-git`| - |
|Cassandra|`gem install rom-cassandra`| √ |
|Kafka|`gem install rom-kafka`| √ |
|MongoDB|`gem install rom-mongo`| - |
|Neo4j|`gem install rom-neo4j`| - |
|Event Store|`gem install rom-event_store`|
|RethinkDB|`gem install rom-rethinkdb`| - |

^INFO
#### How to choose an adapter?

The most popular adapter is `rom-sql`, but some projects connect to an HTTP API, or need the expandability of MongoDB and CouchDB. It's up to you to choose the appropriate solution for your application's needs.
^

## Install rom

Simply install `rom` or add it to your `Gemfile`. Adapters will be auto-loaded based on configuration settings.

For example, if you'd like to use ROM with an SQL database, add following gems to you `Gemfile`:

``` ruby
gem 'rom'
gem 'rom-sql'
```

## Next

ROM needs a setup phase to provide a persistence environment for your entities. The end result is the **container**, an object that provides access to relations and commands, and integrates the two with your mappers.

Depending on your application needs, you may want to use different setup strategies:

* [Quick setup](/learn/core/5.2/quick-setup) - suitable for small scripts
* [Framework setup](/learn/core/5.2/framework-setup) - suitable for custom environments (**advanced usage** only needed when your framework does not provide integration with ROM)
* [Rails](/learn/rails) - setup integrated with Rails

^INFO
Most guide examples are written specifically for the `rom-sql` adapter. If you are using a different one, consult that adapter's documentation as well.
^