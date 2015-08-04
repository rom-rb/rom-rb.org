---
title: Sustainable Development Campaign
date: 2015-08-04
tags: oss,support
author: Piotr Solnica
---
ROM has been in development for a couple of years already, in fact, its [early prototype](https://github.com/solnic/rom-relation/tree/pre-mapper-extraction) was built in 2012, and has gone through multiple phases before the final architecture was introduced in October last year. This has been a huge effort which resulted in the creation of many smaller libraries and, of course, ROM itself.

One of the main reasons that this project was started was to discover a better way of writing Ruby code that would result in a cleaner architecture for the systems we're building. The Ruby ecosystem has mostly been shaped by the Active Record pattern introduced in the Rails framework, but ROM tries to move away from the common approach, so that it's easier to build **and grow** systems built in Ruby.

It's been an interesting journey with lots of experimentation, and we are getting there, as ROM is approaching 1.0.0.

There are a few mind-shifting aspects of ROM which are worth consideration as general programming guidelines in Ruby:

* Prefer simple objects that don't change (mutate) and have a single purpose to exist
* Prefer interfaces that have no side-effects
* Embrace simple data structures rather than complicated objects that mix data and behavior
* Prefer objects over classes, and always treat dependencies explicitly
* Pay attention to boundaries and proper separation of concerns

Those guideliness have led to the decision that ROM will not be a typical Object Relational Mapper which tries to hide your database behind walls of complicated and leaky abstractions and pretend that "you can just use objects". This is the reason why ROM gives you a powerful interface to use your database effectively; which can be levaraged to design your systems with simpler data structures in mind and decouple your application layer from persistence concerns.

Such an approach has a significant impact on **lowering complexity** of your application layer.

## Growing The Ecosystem

ROM is already a big project; if you consider its lower level libraries, over 14 adapters and integration with 3 frameworks. But it goes beyond that - other libraries are being developed that are based the on same programming principles. It is absolutely amazing to see that happening. The ecosystem is growing.

We have reached a point where ROM needs a sustainable pace of development, so that following things can happen:

* Reach 1.0.0 in September
* Extract re-usable APIs into separate libraries so that other projects can benefit from them
* Improve existing adapters to be production-ready (the more the merrier)
* Address all known issues in a timely fashion
* Support users in multiple channels
* Establish a solid release process with a CI setup that can help in developing adapters and extensions

In order to be able to do all of that we need your support.

## Campaign on Bountysource

Bountysource is a service that helps in raising funds for Open Source projects. Its latest feature, called Salt, allows sustainable fundraising on a monthly basis. This makes it possible to support a steady pace of development - which is crucial for a complex project like ROM.

If you'd like to see ROM grow faster, please consider supporting the project through [the campaign](https://salt.bountysource.com/teams/rom-rb).

We want to take the project to the next level with this campaign and hope to expand the team so that more people can work continuously on ROM. We are happy to use the funds to sponsor work on ROM itself and also on any other library that the project could benefit from.

## What's in it for you?

There are many ways in which you and your company can benefit from ROM *today*, but there's still a lot to be done to make ROM simpler to use for the common application use-case. This includes adding convenient, high-level abstractions as well as providing great documentation and other resources that would teach people how to use ROM.

If you're interested in the project but it still feels "weird" or "too complicated", this is exactly the reason that the campaign was started. ROM *should be accessible for everybody*, including less experienced developers. Not only do we want to promote ROM, but also, the general approach to writing Ruby code, which we believe results in a better and more maintainable code-base.

For any questions or concerns, please do not hesitate to [get in touch](https://twitter.com/_solnic_).
