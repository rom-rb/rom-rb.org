``` ruby
class UserRelation < ROM::Relation[:sql]
  dataset :users

  def by_name(name)
    where(name: name)
  end
end
```
