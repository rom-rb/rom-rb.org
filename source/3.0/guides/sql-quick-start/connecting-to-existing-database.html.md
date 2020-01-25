---
chapter: Quick Start
title: Connecting to existing database
---

This article assumes:

* You have a database called `my_db`
* There's a table called `users`

To connect to your database and define a repository for `users` table, simply do:

``` ruby
rom = ROM.container(
  :sql, 'postgres://localhost/my_db', username: 'user', password: 'secret'
)

class UserRepo < ROM::Repository[:users]
  commands :create
end

user_repo = UserRepo.new(rom)
```

## Learn more

* [Repositories Quick Start](/3.0/learn/repositories/quick-start)
* [api::rom-sql::SQL](Gateway)
