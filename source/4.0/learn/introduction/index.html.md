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

Ruby Object Mapper; ROM for short, is a *fast* ruby persistence library with
the goal of providing powerful object mapping capabilities without limiting the
full *power* of the underlying datastore.

More specifically, ROM exists to:

* Isolate the application from persistence details
* Provide minimum infrastructure for mapping and persistence
* Provide shared abstractions for lower-level components
* Provide simple use of *power* features offered by the datastore


## The Problem with ORMs

Object hierarchies are very different from relational hierarchies. 
Relational hierarchies focus on data and its relationships with other data,
whereas objects hold not only data but behavior centered around that data. The
image below attempts to visualize the differences.

![Objects vs Relations](images/objects-vs-relations.jpg)

A fundamental flaw behind ORMs is this idea that it's easy to:

1. Map objects to database tables one-to-one (the
   [ActiveRecord](https://en.wikipedia.org/wiki/Active_record_pattern) design
   pattern); or
  
2. Introduce machinery to translate between objects and persistence
   structures (the
   [DataMapper](https://en.wikipedia.org/wiki/Data_mapper_pattern) pattern)

Both strategies tend to start out fine, but quickly become cumbersome as an 
application transitions to a medium-to-large application.

ActiveRecord style mapping limits your application's modeling to what's
convenient for the database. Your entities tend to map one-to-one with the
tables, and therein lies the problem with the strategy. Many times, an entity is
broken up and stored in multiple tables; following the rules of data
normalization. The ActiveRecord pattern then causes the application domain to
infect itself with intimate knowledge about the entities persistence structure
which sets off a chain of events that ultimately lead to much unnecessary pain.

The DataMapper pattern, while one step better than ActiveRecord style mapping,
still has its focus trained onto creating and managing objects. This pattern
tries to abstract the underlying datastore away which inevitably leads to
performance issues, which either results in bypassing the ORM entirely or to
implementing global tracking state such as identity maps which intern creates
subtle bugs and forces all sorts of nastiness such as dirty tracking.  

Of course, the problems discussed above can often be mitigated by veteran
developers but more often than not, development is slowed due to bug hunting
and increased complexity.

## Why use ROM

ROM provides an alternative way of handling persistence and related concerns.
It focuses on *simplicity* by providing enough *abstractions* to help you
efficiently turn your raw data into meaningful information. 

While most ORM focus on objects and state tracking, ROM focuses on data and
transformations. Users of ROM implement `Relations` which map one-to-one with
datasets (eg: tables). Then using the relations you can associate them with
other relations and query the dataset using the direct features offered by the
datastore. Once raw data has been loaded it gets coerced into configured
datatypes and from there can mapped into whatever format is needed by the
application domain including custom type objects, helpful ROM Structs or plain
old ruby hashes.

The important concept above is during the entire process there is no dirty
tracking, no identity management, no mutable state or anything else. Just *pure*
data being loaded and mapped as result of a **direct** request made from the
application domain. Data can be properly persisted taking advantage of the
features provided by the datastore and our application domain can receive that
data in any form it needs. Furthermore you get the added benefits of:

  * decoupling our application from our persistence layer without sacrificing
    its power features, and
    
  * bypassing the critical problems associated with object relational mapping.

Most likely, a large contingent of developers will see the added abstractions as
extraneous boilerplate. For those people we ask that you give ROM a chance,
embrace its patterns and principles and see just how much easier it is pull and
transform your data. For those who have been burned by *simple* ORMs in the
past, ROM represents a real, solid alternative. 


## Principles & Design

ROM leverages Ruby’s linguistic strengths with a blend of Object Oriented and
Functional styles. Following a powerful composition pattern, every ROM object
shares a common pipeline interface and returns data without side-effects. It’s
also built with dependency-injection in mind; there are no public class-level
interfaces beyond the setup interface.

All ROM components are stand-alone; they are loosely coupled, can be used
independently, and follow the single responsibility principle. A single object
that handles coercion, state, persistence, validation, and all-important
business logic rapidly becomes complex. Instead, ROM provides the infrastructure
that allows you to easily create small, dedicated classes for handling each
concern individually, and then tie them together in a developer-friendly ways.

Above all else ROM favours:

* **Explicitness** over "magic" whenever possible
* **Speed**, because performance is a *feature*
* **Flexibility** in your domain layer's design


## Inspirations, Ideas, and Friends

Like ROM & its fundamental ideas? You should check these out, too:

* [Rich Hickey on state, immutability, and how to leverage OO principles](http://www.infoq.com/presentations/Are-We-There-Yet-Rich-Hickey)
* [Gary Bernhardt on boundaries, immutability, a clean design](https://www.youtube.com/watch?v=yTkzNHF6rMs)
* [Rich Hickey on the importance of simplicity for cognition](https://www.youtube.com/watch?v=rI8tNMsozo0)
* [Robert C. Martin (“Uncle Bob”) on hexagonal architecture](https://www.youtube.com/watch?v=WpkDN78P884)
* [Brad Urani on ActiveRecord vs. Ecto: A Tale of Two ORMs](http://confreaks.tv/videos/railsconf2016-activerecord-vs-ecto-a-tale-of-two-orms)


<!-- ## Criticisms 

Should collect a number of criticisms lobbed against ROM and attempt to answer
them here. Left for future changes. -->


## NEXT

If you're coming from Rails a good place to start is our 
[**ROM Rails Comparison Guide**](/%{version}/learn/introduction/active-record)
otherwise checkout the
[**Core Concepts**](/%{version}/learn/getting-started/core-concepts)
guide to get an overview of all the major parts in ROM.
