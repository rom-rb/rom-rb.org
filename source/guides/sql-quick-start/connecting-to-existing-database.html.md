---
chapter: Quick Start
title: Connecting to existing database
---

This article assumes:

* You have a database called `my_db`
* There's a table called `users` with `name` column
* You have the `rom` and `rom-sql` gems installed

To connect to your database and define a repository for `users` table, simply do:

``` ruby
require "rom"

rom = ROM.container(:sql, 'postgres://localhost/my_db', username: 'user', password: 'secret') do |config|
  config.relation(:users) do
    schema(infer: true)
    auto_struct true
  end
end

users = rom.relations[:users]

users.changeset(:create, name: "Jane").commit

jane = users.where(name: "Jane").one
```

## Learn more

* [Repositories Quick Start](/learn/repository/5.1/quick-start)
* [api::rom-sql::SQL](Gateway)
