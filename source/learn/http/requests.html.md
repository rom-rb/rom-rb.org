---
title: HTTP
chapter: Requests
---

In order to remain client and adapter agnostic, ROM::HTTP does not attempt
to perform the actual process of sending web-queries.  This allows you to
choose your favorite HTTP client library, or even to make use of a
service-specific client gem.

A request handler expects to receive the `#call` method, and is provided with
an HTTP `dataset` object, from which the URL, HTTP verb, headers and query
parameters will be drawn.  The results of this method will be passed directly
into the response handler object's `#call` method, which is expected to return
the ROM standard array of tuples.  Taken together, these two objects will
isolate the specifics of your HTTP library, and service responses from the
rest of your data layer.

```
class RequestHandler
  def call(dataset)
    uri = URI(dataset.uri)

    path  = "/#{dataset.name}/#{dataset.path}"

    client = Faraday.new(uri, headers: dataset.headers)

    response = client.send(dataset.request_method, path, dataset.params)
  end
end


class ResponseHandler
  def call(response, dataset)
    Array([JSON.parse(response.body)]).flatten
  end
end
```
