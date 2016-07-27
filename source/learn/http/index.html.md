---
title: HTTP
chapter: Setup
---

ROM supports HTTP-based services via the `rom-http` adapter, which is
client-agnostic.  The adapter presents a request-response wrapper, allowing
the use of an arbitrary HTTP client gem.

By implementing the request and response handlers, it should be possible to
interact with any arbitrary HTTP service; however as each service provides
different semantics and expectations, `rom-http` is presented as a "batteries
not included" adapter.

Refer to the general [setup](/learn/setup) for information on how to setup
ROM with specific adapters.  `ROM::HTTP` will require some additional
configuration for each of it's Gateways.

## Establishing Gateways

Each remote HTTP host should be established as it's own gateway in the ROM
container.

```ruby
  ROM.container(
    github: [:http, {
      uri: "https://api.github.com", 
      headers: { Accept: 'application/json' },
      request_handler: GithubRequestHandler.new,
      response_handler: GithubResponseHandler.new
    }],
    placeholder: [:http, {
      uri: "https://jsonplaceholder.typicode.com",
      headers: { Accept: 'application/json' },
      request_handler: PlaceholderRequestHandler.new,
      response_handler: PlaceholderResponseHandler.new
    }]
  )
```

`request_handler` and `resposne_handler` are responsible for the work of
communicating with the HTTP server, and processing the response, respectively.
Learn more about them in the [requests](/learn/http/requests) section.  These
objects are used by the [relation](/learn/http/relations) when communicating
with the web server.
