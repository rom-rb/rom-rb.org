# Adapters

Adapters are the basis upon which all of ROM is built. ROM uses adapters to
connect to different data sources. These adapters expose *native* interfaces
as internal data access concerns for other layers.

ROM doesn't have an abstract interface that every adapter must implement -- the
requirements are simple and straightforward. You retain access to the full power
of the raw data access without cluttering up your application or unnecessary
abstractions.

Raw data access alone isn't very useful. The primary way adapters are used in
ROM is as the private implementation details behind
[relations](/guides/basics/relations) and [commands](/guides/basics/commands).

In this section you can learn how to build an adapter for ROM and how to use
specific adapters. There's a lot of common functionality that work across all
adapters, however, each adapter can implement its own unique features.
