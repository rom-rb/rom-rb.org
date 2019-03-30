---
chapter: SQL How To
title: Order with attribute of an associated record
---
This article assumes:

* You have a `users` table
* You have a `teams` table 

We have Users, each users is associated to a Team. Let's imagine we want to get all the users, 
but we want them ordered by Team name, and if they're in the same team, we want them to be 
ordered by creation_date.

``` ruby
module Repositories
  class Users
    def get_ordered_by_team_and_creation_date
      users
        .combine(:team)
        .order('team[:name]', :created_at)
        .to_a
    end
  end
end

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

Repositories::Users.get_ordered_by_team_and_creation_date
```