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
ROM favors explicit definition of components using the included DSL.

### Usable
Small, explicit objects make it easy to use ROM objects as dependencies of your
objects. The interfaces are kept simple to encourage reuse and encapsulation.

### Fast
It's early for ROM yet, but initial benchmarks show promising performance when
compared to other data access libraries.
