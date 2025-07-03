---
chapter: Introduction
sections:
  - active-record
---

$TOC
  1. [What is ROM](#what-is-rom)
  2. [The Problem with ORMs](#the-problem-with-orms)
  3. [Why use ROM](#why-use-rom)
  4. [Principles & Design](#principles-amp-design)
  5. [Our Inspiration](#inspirations-ideas-and-friends)
$TOC

## What is ROM

Ruby Object Mapper (ROM) is a *fast* ruby persistence library with
the goal of providing powerful object mapping capabilities without limiting the
full *power* of the underlying datastore.

More specifically, ROM exists to:

* Isolate the application from persistence details
* Provide minimum infrastructure for mapping and persistence
* Provide shared abstractions for lower-level components
* Provide simple use of *power* features offered by the datastore

## The Problem with ORMs

Object hierarchies are very different from relational hierarchies. Relational
hierarchies focus on data and its relationships whereas objects not only manage
data, but also their *identity* and the *behavior* centered around that data.
When attempting to reconcile those difference and map one to the other, we as
developers end up *splatting* against a concrete wall.

We believe the cause can be attributed to a fundamental flaw behind ORMs; that
is this idea that it's easy to:

1. Map objects to database tables one-to-one (the
[ActiveRecord](https://en.wikipedia.org/wiki/Active_record_pattern) design
pattern); or

2. Introduce machinery to translate between objects and persistence structures
(the [DataMapper](https://en.wikipedia.org/wiki/Data_mapper_pattern) pattern)

Both strategies tend to start out fine, but can quickly become cumbersome as an
application transitions to a medium-to-large application.

ActiveRecord style mapping has the benefit of aiding in rapid prototyping, which works
great in basic CRUD scenarios but it limits application modeling to what's
convenient for the database. Entities will tend to map one-to-one with tables,
which leads to knowledge of the persistence structure infecting the application
domain, leading to code that's difficult to change.

The DataMapper pattern, while one step better than ActiveRecord style mapping,
still has its focus trained onto creating and managing objects. The pattern
solves the one-to-one mapping issue but in doing so creates a host of others.
The whole apparatus needed to manage all of those objects inevitably leads to
performance issues and object state tracking which results in developers
bypassing the ORM entirely.

The problems with ORMs are numerous and the above issues only begin to scratch
the surface. If you're interested in further reading on the subject, we suggest:

* [ORM Hate by Martin Fowler](https://martinfowler.com/bliki/OrmHate.html)
* [The Vietnam of Computer Science by Ted Neward](http://blogs.tedneward.com/post/the-vietnam-of-computer-science/)

## Why use ROM

ROM provides an alternative way of handling persistence and related concerns.
It focuses on *simplicity* by providing enough *abstractions* to help you
efficiently **turn your raw data into meaningful information**.

While many ORMs focus on objects and state tracking, **ROM focuses on data and
transformations**. Users of ROM implement `Relations`, which give access to data.
Then using the relations you can associate them with other relations and query
the data using features offered by the datastore. Once raw data has been loaded,
it gets coerced into configured data types, and from there can be mapped into
whatever format is needed by the application domain, including plain ruby hashes,
convenient ROM Structs or custom objects.

The important concept above is that during the entire process there is no dirty
tracking, no identity management and no mutable state. Just *pure* data being
loaded and mapped as result of a **direct** request made from the application
domain. Data can be persisted in ways that take advantage of the features
provided by the datastore and the application domain can receive that data in
any form it needs. Furthermore, you get the added benefits of:

* decoupling the application from the persistence layer without sacrificing
  flexibility, and
* bypassing the critical problems associated with object relational mapping
  and mutable state

Most likely, a decent percentage of developers will see the added abstractions
as extraneous boilerplate. For those people we ask that you give ROM a chance,
embrace its patterns and principles and see just how much easier it is to pull
and transform your data. For those who have been burned by *simple* ORMs in the
past, ROM represents a real, solid alternative.


## Principles & Design

ROM leverages Ruby’s linguistic strengths with a blend of Object Oriented and
Functional styles. Following a powerful composition pattern, every ROM object
shares a common pipeline interface and returns data without side-effects.

All ROM components are stand-alone; they are loosely coupled, can be used
independently, and follow the single responsibility principle. A single object
that handles coercion, state, persistence, validation, and all-important
business logic rapidly becomes complex. Instead, ROM provides the infrastructure
that allows you to easily create small, dedicated classes for handling each
concern individually, and then ties them together in a developer-friendly ways.

Above all else ROM favors:

* **Explicitness** over "magic" whenever possible
* **Speed**, because performance is a *feature*
* **Flexibility** in your domain layer's design


## Inspirations, Ideas, and Friends

Like ROM & its fundamental ideas? You should check these out, too:

* [Rich Hickey on state, immutability, and how to leverage OO principles](http://www.infoq.com/presentations/Are-We-There-Yet-Rich-Hickey)
* [Gary Bernhardt on boundaries, immutability, and clean design](https://www.youtube.com/watch?v=yTkzNHF6rMs)
* [Rich Hickey on the importance of simplicity for cognition](https://www.youtube.com/watch?v=rI8tNMsozo0)
* [Brad Urani on ActiveRecord vs. Ecto: A Tale of Two ORMs](https://www.youtube.com/watch?v=_wD25uHx_Sw)

<!-- ## Criticisms

Should collect a number of criticisms lobbed against ROM and attempt to answer
them here. Left for future changes. -->


## NEXT

If you're coming from Rails a good place to start is our
[**ROM Rails Comparison Guide**](/%{version}/learn/introduction/active-record)
otherwise checkout the
[**Core Concepts**](/%{version}/learn/getting-started/core-concepts)
guide to get an overview of all the major parts in ROM.
