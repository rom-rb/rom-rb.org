### Philosophy

* Simple is best
* Composition is powerful
* Apps require architectural freedom
* Reading and writing are distinct problems
* Decouple apps from query details
* Universal query interfaces only add complexity

ROM leverages Ruby’s linguistic strengths with a blend of Object Oriented and Functional styles.
Following a powerful composition pattern, every ROM object shares a common pipeline interface
and returns data without side-effects. It’s also built with dependency-injection in mind; there
are no public class-level interfaces beyond the setup interface.

All ROM components are stand-alone: they are loosely coupled, can be used independently, and
follow the single responsibility principle. A single object that handles coercion, state,
persistence, validation, and all-important business logic rapidly becomes complex. Instead, ROM
provides the infrastructure that allows you to easily create small, dedicated classes for handling
each concern individually, and then tie it together in a developer-friendly way.

###ROM is not an ORM
ROM is based on several concepts and decisions that differentiate it from commonplace Ruby ORMs.
The fundamental flaw behind ORMs is the idea that it could be easy to either:

1. Map objects to database tables one-to-one (the
[ActiveRecord](https://en.wikipedia.org/wiki/Active_record_pattern) design pattern); or
1. Introduce a complex machinery to translate between objects and persistence structures (the
[DataMapper](https://en.wikipedia.org/wiki/Data_mapper_pattern) pattern)

Both strategies are cumbersome. ActiveRecord writes you into a corner, limiting your application’s
modeling to what’s convenient for the database. ROM isn’t bound one-to-one with database tables,
and that enables developers to use the best persistence tool for the task at hand.

DataMapper is one step better, but retains the complexity and ambiguity of managing mutable objects.
ROM bypasses that complexity by working statelessly.

###Inspirations, Ideas, and Friends
Like ROM & its fundamental ideas? You should check these out, too:

* [Rich Hickey on state, immutability, and how to leverage OO principles](http://www.infoq.com/presentations/Are-We-There-Yet-Rich-Hickey)
* [Gary Bernhardt on boundaries, immutability, a clean design](https://www.youtube.com/watch?v=yTkzNHF6rMs)
* [Rich Hickey on the importance of simplicity for cognition](https://www.youtube.com/watch?v=rI8tNMsozo0)
* [Robert C. Martin (“Uncle Bob”) on hexagonal architecture](https://www.youtube.com/watch?v=WpkDN78P884)
