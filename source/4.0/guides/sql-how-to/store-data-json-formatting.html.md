---
chapter: SQL How To
title: Store data as JSON Strings
---

Let's assume that you are using a storage system like MySQL and you want to store some data in JSON format. Let's also
assume that you don't have Hash kind like Type provided by default by this storage system (like HStore on Postgres,
in such case you can use [built-in PG types](https://rom-rb.org/4.0/learn/sql/schemas/#postgresql-types)).

You can use `Dry::Types:Constructor` in order to make your own way to process data, and give it to your ROM::Relation 
in order that ROM uses this to store and read this data.

You can use same technique if you need any data processing before it goes to your Datastore (like YAML serialization).

```ruby
JSONRead = Dry::Types::Constructor.new(Dry::Types['string'], fn: ->(v) { JSON.parse(v) })
JSONWrite = Dry::Types::Constructor.new(Dry::Types['string'], fn: ->(v) { JSON.dump(v) })
```
Those `Dry::Types::Constructor` defines the way to translate input object to String.

You can test those by doing this:
```ruby
h = {'a'=>'a', 'b'=>{ 'c'=>'c'}}
JSONWrite[h]
=> "{\"a\":\"a\",\"b\":{\"c\":\"c\"}}"

JSONRead[JSONWrite[h]]
=> {"a"=>"a", "b"=>{"c"=>"c"}}

JSONRead[JSONWrite[h]] == h
=> true
```
Tips: You can use [Oj gem](https://github.com/ohler55/oj) if you want to keep symbol keys when serializing JSON.

Then on your relations:
```ruby
module Relations
  class Users < ROM::Relation[:sql]
    schema(:users) do
      attribute :hash_attribute, JSONWrite, read: JSONRead
      attribute :array_attribute, JSONWrite, read: JSONRead
    end
  end
end
```
Here, we assume that you're using SQL datastore, with a `users` table that has `hash_attribute` column which is a String
and a `array_attribute` column that is also a String.

Now you'll have ruby Hash on your ROM::Struct automatically instead of Strings in JSON format.

This article as been inspired by this [forum post](https://discourse.rom-rb.org/t/methods-of-storing-arrays-in-mysql/305).
