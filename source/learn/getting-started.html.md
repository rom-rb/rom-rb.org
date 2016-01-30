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

## Overview

ROM encourages a clear separation between your application domain and the data
access layer. This is more than just hiding access behind methods. Your
application is not coupled to the details of data retrieval or manipulation.

The figure below represents the data flow through an application using ROM:

<img src="/images/rom-design-overview.png"/>

### Reading

1. Your application requests data from a <mark>Relation</mark> (or its easier
   cousin <mark>Repository</mark>)
2. Data is read from the <mark>Datastore</mark> using the <mark>Adapter</mark>
3. The result is returned to your application
   * It can also optionally be mapped to domain objects using
     <mark>Mappers</mark>

### Writing

1. Your application calls a <mark>Command</mark> to perform a Create, Update,
   Delete, or custom operation
1. The command runs using its underlying Relation and Adapter to modify the
   datastore
1. The result is returned to your application

#### Adapters

ROM uses adapters to connect to different data sources (a database, a csv file -
it doesn't matter) and exposes a native CRUD interface to its relations.

#### Repositories

A repository provides a convenient interface for fetching domain-specific
entities and value objects from a database. It's a higher-level abstraction
built on top of relation and mapping layers.

#### Relations

A relation is defined as a set of tuples identified by unique pairs of
attributes and their values. In ROM it is an object that responds to `#each`
which yields hashes. It is backed by <mark>a dataset object</mark> provided by
the adapter.

#### Mappers

A mapper is an object that takes a relation and maps it into a different
representation. ROM provides a DSL to define mappers or you can register your
own mapper objects.

#### Commands

Commands in ROM are intended to safely modify data. Commands can be used to
create, update and delete. They are usually provided by the adapter, but you may
define your own.

## Next

Continue on to read about [Setup](/learn/setup)
