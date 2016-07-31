---
chapter: Getting Started
title: Installation
sections:
  - block-style-setup
  - rails-setup
---

Choose one or more adapters that you intend to use, and run the install command
for each one (or add it to your `Gemfile`)

Compatible with rom 2.0:

|Adapter|Install Command|Production ready?|
|-------|---------------|---|
|SQL|`gem install rom-sql`| √ |
|Yesql|`gem install rom-yesql`| √ |
|CouchDB|`gem install rom-couchdb`| √ |
|HTTP|`gem install rom-http`| √ |
|Git|`gem install rom-git`| - |
|RethinkDB|`gem install rom-rethinkdb`| - |

Outdated (help wanted!) adapters:

|Adapter|Install Command|Production ready?
|-------|---------------|---|
|CSV|`gem install rom-csv`| √ |
|YAML|`gem install rom-yaml`| √ |
|Cassandra|`gem install rom-cassandra`| √ |
|Kafka|`gem install rom-kafka`| √ |
|MongoDB|`gem install rom-mongo`| - |
|Neo4j|`gem install rom-neo4j`| - |
|Event Store|`gem install rom-event_store`|

> #### How to choose an adapter?
>
> The most popular adapter is `rom-sql`, but some projects connect to an HTTP
> API, or need the expandability of MongoDB and CouchDB. It's up to you to
> choose the appropriate solution for your application's needs.

## Install rom-repository

Simply install `rom-repository` or add it to your `Gemfile`. Adapters will be
auto-loaded based on configuration settings.

For example, if you'd like to use ROM with an SQL database, add following gems to
you `Gemfile`:

``` ruby
gem 'rom-repository'
gem 'rom-sql'
```

## Next

ROM needs a setup phase to provide a persistence environment for your entities.
The end result is the **container**, an object that provides access to relations
and commands, and integrates the two with your mappers.

Depending on your application needs, you may want to use different setup strategies:

* [Block Style](/learn/getting-started/block-style-setup) - suitable for small scripts
* [Rails](/learn/getting-started/rails-setup) - setup integrated with Rails
* [Flat Style](/learn/advanced/flat-style) - suitable for custom environments (**advanced usage**)

> Note: Most guide examples are written specifically for the `rom-sql` adapter.
> If you are using a different one, consult that adapter's documentation as
> well.
