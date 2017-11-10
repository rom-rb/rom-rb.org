---
chapter: Introduction
sections:
  - active-record
---

$TOC
  1. [What is ROM](#what-is-rom)
  2. [The Problem with ORMs](#the-problem-with-orms)
  3. [Why We are Different](#why-we-are-different)
  4. [Our Design](#our-design)
  5. [Our Inspiration](#inspirations-ideas-and-friends)
$TOC

## What is ROM

Ruby Object Mapper (ROM) is a *fast* Ruby persistence library with the goal to
provide powerful object mapping capabilities without limiting the full *power* of
your datastore.

More specifically, ROM exists to:

* Isolate the application from persistence details
* Provide minimum infrastructure for mapping and persistence
* Provide shared abstractions for lower-level components
* Provide simple use of *power* features offered by the datastore


## The Problem with ORMs

Object hierarchies are very different from relational hierarchies. 
Relational hierarchies focus on data and its relationships with other data,
whereas objects hold not only data but behavior centered around that data.

A visual example of this can be seen below:

![objects vs relations](images/objects-vs-relations.jpg)

Taking a look at the Address entity on the left, you'll see that to
rehydrate an Address, data is needed from Addresses and PostCodes on the right.
While it's a trivial example, it does illustrate the nested nature of objects
vs the reference nature of stored data.

A fundamental flaw behind ORMs is this idea that it's easy to:

1. Map objects to database tables one-to-one (the
   [ActiveRecord](https://en.wikipedia.org/wiki/Active_record_pattern) design
   pattern); or
  
2. Introduce machinery to translate between objects and persistence
   structures (the
   [DataMapper](https://en.wikipedia.org/wiki/Data_mapper_pattern) pattern)

Both strategies tend to start out fine, but can quickly become cumbersome as a
small application transitions into a medium-to-large application.

ActiveRecord style mapping limits your application's modeling to what's
convenient for the database. Your entities tend to map one-to-one with the
tables in the database, and therein lies the problem with the strategy. Many
times, an entity is broken up and stored in multiple tables; following the rules
of data normalization. The ActiveRecord pattern then, by its very nature, causes
the application domain to infect itself with intimate knowledge about
rehydrating entities which sets off a chain of events that ultimately lead to
much unnecessary pain, especially when we all know applications
inevitably change.

The DataMapper pattern, while one step better than ActiveRecord style mapping,
still retains the complexity and ambiguity of managing mutable objects.

Of course, the problems discussed above can be mitigated by custom translation
layers or custom abstractions but at that point you're just creating a custom
ORM over your old ORM. Simply put, mapping relations to objects and vice versa
is a hard, unsolved problem.


## Why We are Different

ROM focuses on *simplicity* by providing enough *abstractions* to help you
efficiently turn your raw data into meaningful information.

Unlike most ORMs where you configure how the object should look and the ORM
goes off and tries to pull it all together, ROM takes a difference approach.
With ROM you use `Relations` which map one-to-one with datasets (eg: tables). 
Then using the relations you can on-the-fly query the dataset

These
relations provide apis to describe what the incoming data types should be as well
as any relationships to other data that may be present. 


## Our Design

ROM leverages Ruby’s linguistic strengths with a blend of Object Oriented and
Functional styles. Following a powerful composition pattern, every ROM object
shares a common pipeline interface and returns data without side-effects. It’s
also built with dependency-injection in mind; there are no public class-level
interfaces beyond the setup interface.


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

Check out ROM's [**Philosophy**](/%{version}/learn/introduction/philosophy) to know more
about the philosophy behind ROM and the project's origins, or dive straight into
code with the [**Getting Started**](/%{version}/learn/getting-started) guide.


<!--- RANDOM NOTES BELOW   ------>

Walks you into a pit of success

