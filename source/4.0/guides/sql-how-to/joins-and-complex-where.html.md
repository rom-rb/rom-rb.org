---
chapter: SQL How To
title: Use complex where clauses with joins
---


Suppose you have an application which has `features` and `users`.
Some features are restricted to certain users while others are open to everyone.

* You have a `features` table, which has an `id` and `name`
* You have a `feature_restrictions` table, which has an `user_id` and `feature_id`

When a feature has no `feature_restriction`, the feature is available to everyone. When a feature has a `feature_restriction`,
only the specified `user_id` can access the feature.

We'd like to have one method that returns the available `features` for a given `user_id`.
That means features that are unrestricted AND features that are restricted to the given user.

This can easily be achieved with a `left_join` and a `where` clause:

``` ruby
module Relations
  class Features < ROM::Relation[:sql]
    schema(:features) do
      attribute :id, ROM::Types::Int
      attribute :name, ROM::Types::String

      associations do
        has_many :feature_restrictions
      end
    end

    def available_features(user_id)
      distinct
        .left_join(:feature_restrictions)
        .where do |r|
          r[:feature_restrictions][:user_id].is(nil) |
            r[:posts_users][:user_id].is(user_id)
        end
    end
  end

  class FeatureRestrictions < ROM::Relation[:sql]
    schema(:users) do
      attribute :feature_id, ROM::Types::Int
      attribute :user_id, ROM::Types::Int

      associations do
        belongs_to :feature
      end
    end
  end
end
```

## Learn more

* [Repositories Quick Start](/learn/repositories/quick-start)
* [api::rom-sql::SQL](Gateway)
