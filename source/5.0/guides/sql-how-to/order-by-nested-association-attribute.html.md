---
chapter: SQL How To
title: Order with attribute of an associated record
---
This article assumes:

* You have a `users` table
* You have a `teams` table 

We have Users, each users is associated to a Team. Let's imagine we want to get all the users, 
but we want them ordered by Team name, and if they're in the same team, we want them to be 
ordered by creation date. Here are our relations:

``` ruby
module Relations
  class Users < ROM::Relation[:sql]
    attribute :created_at, ROM::Types::DateTime

    schema(:users) do
      associations do
        belongs_to :team
      end
    end
  end

  class Teams < ROM::Relation[:sql]
    schema(:teams) do
      attribute :name, ROM::Types::String

      associations do
        has_many :users
      end
    end
  end
end
```

And here is the code to get such ordering:

```
2.5.3 :003 > users.join(:teams).order { |r| [r[:teams][:name], r[:users][:created_at]] }
 => #<Relations::Users name=ROM::Relation::Name(users) dataset=#<Sequel::Mysql2::Dataset: 
 "SELECT `users`.`id`, `users`.`name`, `users`.`created_at`, `users`.`team_id` FROM `users`
 INNER JOIN `teams` ON (`users`.`team_id` = `teams`.`id`) ORDER BY `teams`.`name`, `users`.
 `created_at`">>
2.5.3 :004 > users.combine(:teams).join(:teams).order { |r| [r[:teams][:name], r[:users][:created_at]] }.to_a
 => [{:id=>1, :name=>"John Doe", :created_at=>2019-07-07 15:54:14 +0200, :team_id=>1, :team=>{:id=>1, :name=>"A team"}},
 {:id=>3, :name=>"Jack Doe", :created_at=>2019-07-07 15:54:27 +0200, :team_id=>1, :team=>{:id=>1, :name=>"A team"}},
 {:id=>2, :name=>"Jane Doe", :created_at=>2019-07-07 15:54:22 +0200, :team_id=>2, :team=>{:id=>2, :name=>"B team"}}]
```

If you want to know more about how you can use "#order" method, you can take a look at the 
['rom-sql' specs](https://github.com/rom-rb/rom-sql/blob/73701c35656501045b52859671e4acf5fab35905/spec/unit/relation/order_spec.rb).
