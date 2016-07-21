---
title: Getting Started
chapter: Getting Started
---

# Getting Started

## Install

Choose one or more adapters you intend to use, and run the install command for
each one:

|Adapter|Install Command|
|-------|---------------|
|SQL|`gem install rom-sql`|
|Cassandra|`gem install rom-cassandra`|
|MongoDB|`gem install rom-mongo`|
|CouchDB|`gem install rom-couchdb`|
|Neo4j|`gem install rom-neo4j`|
|Event Store|`gem install rom-event_store`|
|RethinkDB|`gem install rom-rethinkdb`|
|HTTP|`gem install rom-http`|
|CSV|`gem install rom-csv`|
|YAML|`gem install rom-yaml`|

> #### How to choose an adapter?
>
> The most popular adapter is `rom-sql`, but some projects connect to an HTTP
> API, or need the expandability of MongoDB and CouchDB. It's up to you to
> choose the appropriate solution for your application's needs.

## Require

Call `require` for `rom-repository` and each adapter you want to use in your
project:

```ruby
require 'rom-repository'  # repository makes simple operations easy

# ... and don't forget adapters
require 'rom-sql'         # use this if you installed sql adapter
require 'rom-http'        # and this for http
require 'rom-couchdb'     # ... etc
```

## Next

Continue on to read about [Setup](/learn/setup)
