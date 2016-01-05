# Advanced Topics

##Advanced Setup - Flat Style
Block style doesn’t fit all use cases, so you can also break it down into multiple steps in *flat style*. 

To use flat style, create a `ROM::Configuration` object. This is the same object that gets yielded into your 
block in block-style setup, so the API is identical. 

```ruby
configuration = ROM::Configuration.new(:memory, 'memory://test')
configuration.relation(:users)
# ... etc
```

When you’re finished configuring, pass the configuration object to `ROM.container` to generate the finalized 
container. There are no differences in the internal semantics between block-style and flat-style setup.

