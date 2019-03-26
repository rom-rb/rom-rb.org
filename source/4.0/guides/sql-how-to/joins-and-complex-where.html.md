---
chapter: SQL How To
title: Use complex where clauses with joins
---

This article assumes:

* You have a `users` table
* You have a `posts_users` table 

Let's imagine that you have some Users and each has many Posts associated. You decided to implement this relation 
with a join table `posts_users`, that has in its attributes both `user_id` and `post_id`.

Let's imagine that you want to get all the `post_id` associated to some user and all Users who don't 
have any `post_id`.

``` ruby
module Relations
  class Users < ROM::Relation[:sql]
    attribute :id, ROM::Types::Int

    schema(:users) do
      associations do
        has_many :posts_users
      end
    end

    def get_post_by_id_or_nil(post_id)
      distinct
        .left_join(:posts_users)
        .where do |r|
          r[:posts_users][:post_id].is(nil) |
            r[:posts_users][:post_id].is(post_id)
        end
    end
  end

  class PostsUsers < ROM::Relation[:sql]
    schema(:posts_users) do
      attribute :post_id, ROM::Types::Int
      attribute :user_id, ROM::Types::Int

      associations do
        belongs_to :user
      end
    end
  end
end
```

## Learn more

* [Repositories Quick Start](/learn/repositories/quick-start)
* [api::rom-sql::SQL](Gateway)
