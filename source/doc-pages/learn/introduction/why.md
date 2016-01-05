# Why?

Many Rubyists start their journey being exposed to Rails and its favored
object relational mapping (ORM) library, `Active Record`. `Active Record` is an
implementation of the **Active Record** pattern. In this pattern, objects carry
the data *and* the behavior that operates on that data.

`Active Record` pattern has been widely adopted by the ruby community, mostly due
to the success of Rails; however, it's a pattern with well known shortcomings. In
complex applications `Active Record` is no longer a good choice as it tightly
couples your application domain layer with the underlaying database. It's
especially problematic in Rails where its `ActiveRecord` ORM provides a gigantic
interface to handle many different concerns. As a result, many Rails applications
have been suffering from rapidly increasing complexity, caused by internal
coupling and lack of clean domain layer, to a point where *maintaining and growing
an application becomes very difficult*.

The *benefit* of using `Active Record`, which speeds up initial development and
lowers the costs during early stages of a project, quickly *becomes irrelevant*
once complexity of the application grows and adding new features and fixing bugs
takes more time than it should.

ROM provides an alternative way to handling persistence and related concerns. It
can be used as effectively, in terms of fast development, as Active Record, with
the great benefit of being able to adjust your design to the growing complexity
of your application. *Lack of coupling* between your application *domain layer* and
the underlaying databases simplifies your code and *the persistence layer*, handled
by ROM components, gives you powerful interfaces to help dealing with complexity
and performance issues.

When using ROM you are not limited to any ORM abstraction, because ROM doesn't
have it. Instead, you can leverage features of your database using adapter
interfaces, which can also help in reducing complexity of your application.

ROM focuses on *simplicity* and *removes unnecessary abstractions*. It helps you
in working efficiently with the data and turning it into meaningful information.

### Flexible

The single biggest reason to use ROM is to have the freedom to design the domain
layer however you like -- you aren't tied to the structure of your database. This
flexibility is of primary concern to ROM.

### Powerful

ROM makes it easy to work with different datasources. A minimum structure is
provided with more adapters being created every day. The primary adapter,
[`rom-sql`](https://github.com/rom-rb/rom-sql), is built on the battle-tested
[`Sequel`](https://github.com/jeremyevans/sequel) library which is stable and
brings with it immediate support for many different types of databases.

### Small

Each piece of ROM is small and understandable making it easier to find what you
need when adding the library to your project.

### Explicit

ROM favors explicitness and avoiding "magic" as much as possible.

### Usable

ROM components are small, simple to use and allows powerful composition. Higher-level
abstractions can be easily built on top of lower-level components.

### Fast

ROM is fast, and it gives you the power to improve performance easily when default
behavior doesn't satisfy you. No magic, no leaky abstractions, you're in control.

