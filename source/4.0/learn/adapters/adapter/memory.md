# Memory Adapter

ROM ships with a built-in memory adapter that is used in the ROM test suite but
can also be use as a base for building other adapters that can benefit from its
in-memory operations.

## Setup

To setup an in-memory gateway you simply provide adapter identifier:

``` ruby
ROM.setup(:memory)
```

No additional options are supported.

## Defining Relations

``` ruby
class Users < ROM::Relation[:memory]
end
```
