---
title: Setup
chapter: Setup
---

# Overview

ROM needs a setup phase to provide a persistence environment for your entities.
The end result is the **container**, an object that provides access to relations
and commands, and integrates the two with your mappers.

Depending on your environment, you may want to use different setup strategies:

* [Block Style](/learn/setup/block-style) - suitable for small scripts
* [Rails](/learn/setup/rails) - setup integrated with Rails
* [Flat Style](/learn/advanced/flat-style) - suitable for custom environments
  (advanced usage)

> Note: Most guide examples are written specifically for the `rom-sql` adapter.
> If you are using a different one, consult that adapter's documentation as
> well.
